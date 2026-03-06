document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".tag-autocomplete").forEach((wrapper) => {
    const input = wrapper.querySelector("[data-tag-autocomplete-input]");
    const list = wrapper.querySelector("[data-tag-autocomplete-list]");
    const url = wrapper.dataset.autocompleteUrl;

    if (!input || !list || !url) return;

    let timer = null;

    const closeList = () => {
      list.innerHTML = "";
      list.style.display = "none";
    };

    const currentToken = () => {
      const value = input.value;
      const parts = value.split(",");
      return parts[parts.length - 1].trim();
    };

    const replaceCurrentToken = (selectedTag) => {
      const value = input.value;
      const parts = value.split(",");
      parts[parts.length - 1] = ` ${selectedTag}`; // 最後の入力中部分を置き換える
      input.value = parts
        .map((p, i) => (i === 0 ? p.trimStart() : p))
        .join(",")
        .replace(/^,/, "")
        .trimStart();

      // 次の入力しやすさのため末尾に ", " を付ける
      if (!input.value.endsWith(",")) {
        input.value = input.value.replace(/\s*$/, "") + ", ";
      }
      closeList();
      input.focus();
    };

    const renderList = (items) => {
      if (!items || items.length === 0) {
        closeList();
        return;
      }

      list.innerHTML = "";
      items.forEach((name) => {
        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "tag-autocomplete__item";
        btn.textContent = `#${name}`;

        // mousedown を使うと input blur より先に拾える
        btn.addEventListener("mousedown", (e) => {
          e.preventDefault();
          replaceCurrentToken(name);
        });

        list.appendChild(btn);
      });

      list.style.display = "block";
    };

    input.addEventListener("input", () => {
      clearTimeout(timer);

      timer = setTimeout(async () => {
        const q = currentToken();
        if (!q) {
          closeList();
          return;
        }

        try {
          const res = await fetch(`${url}?q=${encodeURIComponent(q)}`, {
            headers: { Accept: "application/json" }
          });
          if (!res.ok) throw new Error("autocomplete request failed");

          const items = await res.json();
          renderList(items);
        } catch (e) {
          closeList();
          console.error(e);
        }
      }, 200);
    });

    input.addEventListener("blur", () => {
      // クリック選択の邪魔をしないよう少し遅らせる
      setTimeout(closeList, 120);
    });

    input.addEventListener("focus", () => {
      // フォーカス時に再表示したい場合はここで input イベントを発火してもOK
    });
  });
});