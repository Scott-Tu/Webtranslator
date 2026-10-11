import Foundation

/// 注入到網頁裡的 JavaScript。
/// 它在獨立的 content world 執行，網頁自己的程式碼看不到也改不到它，但兩者共用同一份 DOM。
enum Scripts {
    static let core = #"""
    (() => {
      if (window.__wt) { return; }

      // 這些元素內的文字不翻譯（程式碼、輸入框、腳本、日文假名注音等）
      const SKIP = new Set(['SCRIPT', 'STYLE', 'NOSCRIPT', 'TEXTAREA', 'CODE', 'PRE', 'KBD', 'SAMP',
                            'SVG', 'MATH', 'INPUT', 'SELECT', 'OPTION', 'IFRAME', 'CANVAS', 'TEMPLATE',
                            'RT', 'RP']);
      const SKIP_SELECTOR = 'script,style,noscript,textarea,code,pre,kbd,samp,svg,math,template,' +
                            '[contenteditable=""],[contenteditable="true"],[translate="no"],.notranslate';
      // 整段一起翻譯的區塊；裡面只能有文字和下面這些純樣式的行內元素（沒有連結、圖片、換行）
      const BLOCKS = 'p,li,h1,h2,h3,h4,h5,h6,td,th,dt,dd,blockquote,figcaption,caption,label,summary,div';
      const INLINE = new Set(['B', 'STRONG', 'I', 'EM', 'SPAN', 'SMALL', 'MARK', 'U', 'S', 'SUB', 'SUP',
                              'ABBR', 'CITE', 'Q', 'TIME', 'FONT']);
      const LETTER = /\p{L}/u;

      const state = {
        token: Math.random().toString(36).slice(2),
        units: [],          // { kind: 'text', node } 或 { kind: 'block', el }
        originals: [],      // text: 原文字串；block: 原本的子節點陣列
        translations: [],   // text: 譯文字串；block: 譯文的文字節點
        active: false,      // 這個頁面是否已開始翻譯
        showing: 'original',
        timer: null
      };

      function onlyInlineText(el) {
        for (const child of el.childNodes) {
          if (child.nodeType === Node.TEXT_NODE) {
            if (child.__wtId !== undefined) { return false; }
          } else if (child.nodeType === Node.ELEMENT_NODE) {
            if (!INLINE.has(child.tagName) || child.__wtId !== undefined || !onlyInlineText(child)) { return false; }
          } else if (child.nodeType !== Node.COMMENT_NODE) {
            return false;
          }
        }
        return true;
      }

      function isMergeableBlock(el) {
        if (el.__wtId !== undefined || el.childElementCount === 0) { return false; }
        const text = el.textContent;
        if (text.length > 3000 || !LETTER.test(text)) { return false; }
        if (!onlyInlineText(el)) { return false; }
        return !el.closest(SKIP_SELECTOR);
      }

      function addUnit(unit, original, text, items) {
        const id = state.units.length;
        state.units.push(unit);
        state.originals.push(original);
        state.translations.push(null);
        items.push({ id, text });
        return id;
      }

      function collect() {
        const items = [];
        if (!document.body) { return { token: state.token, items }; }

        // 第一步：句子被 <b>、<span> 切成好幾段的區塊，整段一起翻，譯文才通順
        for (const el of document.body.querySelectorAll(BLOCKS)) {
          if (!isMergeableBlock(el)) { continue; }
          el.__wtId = addUnit({ kind: 'block', el }, Array.from(el.childNodes), el.textContent.trim(), items);
        }

        // 第二步：其餘的文字節點逐一翻譯
        const walker = document.createTreeWalker(
          document.body,
          NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT,
          {
            acceptNode(node) {
              if (node.nodeType === Node.ELEMENT_NODE) {
                if (node.__wtId !== undefined || SKIP.has(node.tagName.toUpperCase()) ||
                    node.isContentEditable || node.getAttribute('translate') === 'no' ||
                    node.classList.contains('notranslate')) {
                  return NodeFilter.FILTER_REJECT;   // 整個子樹都跳過
                }
                return NodeFilter.FILTER_SKIP;       // 元素本身不收集，但繼續往下找
              }
              if (node.__wtId !== undefined) { return NodeFilter.FILTER_SKIP; }
              const value = node.nodeValue;
              if (!value || !LETTER.test(value)) { return NodeFilter.FILTER_SKIP; }
              return NodeFilter.FILTER_ACCEPT;
            }
          }
        );
        let node;
        while ((node = walker.nextNode())) {
          node.__wtId = addUnit({ kind: 'text', node }, node.nodeValue, node.nodeValue.trim(), items);
        }

        if (items.length > 0) {
          state.active = true;
          state.showing = 'translated';
        }
        return { token: state.token, items };
      }

      function keepWhitespace(original, text) {
        const lead = original.match(/^\s*/)[0];
        const trail = original.match(/\s*$/)[0];
        return lead + text + trail;
      }

      function render(id, translated) {
        const unit = state.units[id];
        const value = translated ? state.translations[id] : state.originals[id];
        if (value === null) { return; }
        if (unit.kind === 'text') {
          unit.node.nodeValue = value;
        } else if (translated) {
          unit.el.replaceChildren(value);
        } else {
          unit.el.replaceChildren(...value);
        }
      }

      function apply(token, items) {
        if (token !== state.token) { return false; }
        for (const item of items) {
          const unit = state.units[item.id];
          if (!unit) { continue; }
          state.translations[item.id] = unit.kind === 'text'
            ? keepWhitespace(state.originals[item.id], item.text)
            : document.createTextNode(item.text);
          if (state.showing === 'translated') { render(item.id, true); }
        }
        return true;
      }

      function showOriginal() {
        state.showing = 'original';
        state.units.forEach((_, i) => { if (state.translations[i] !== null) { render(i, false); } });
        return true;
      }

      function showTranslated() {
        state.showing = 'translated';
        state.units.forEach((_, i) => { if (state.translations[i] !== null) { render(i, true); } });
        return true;
      }

      function reset() {
        showOriginal();
        state.units.forEach((unit) => { delete (unit.kind === 'text' ? unit.node : unit.el).__wtId; });
        state.units = [];
        state.originals = [];
        state.translations = [];
        state.active = false;
        state.token = Math.random().toString(36).slice(2);
        return true;
      }

      function sample() {
        const body = document.body ? document.body.innerText : '';
        return (document.title + '\n' + body).slice(0, 4000);
      }

      // 動態載入的內容（無限捲動、展開更多等）：通知 App 補翻新出現的文字。
      // 我們自己替換區塊內容造成的變動（target 帶有 __wtId）不算。
      const observer = new MutationObserver((mutations) => {
        if (!state.active || state.showing !== 'translated') { return; }
        if (!mutations.some((m) => m.addedNodes.length > 0 && m.target.__wtId === undefined)) { return; }
        clearTimeout(state.timer);
        state.timer = setTimeout(() => {
          window.webkit.messageHandlers.wt.postMessage('changed');
        }, 700);
      });
      const startObserving = () => {
        if (document.body) { observer.observe(document.body, { childList: true, subtree: true }); }
      };
      if (document.body) { startObserving(); }
      else { document.addEventListener('DOMContentLoaded', startObserving); }

      window.__wt = { collect, apply, showOriginal, showTranslated, reset, sample };
    })();
    """#
}
