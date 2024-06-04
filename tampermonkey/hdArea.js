// ==UserScript==
// @name         HDArea复制种子链接
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://hdarea.club/torrents.php*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=bing.com
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    const passkey = "";

    // Your code here...
    function Toast(msg, duration) {
        duration = isNaN(duration) ? 3000 : duration;
        var m = document.createElement('div');
        m.innerHTML = msg;
        m.style.cssText = "max-width:60%;"
            + "min-width: 150px;"
            + "padding:0 14px;"
            + "height: 40px;"
            + "color: rgb(255, 255, 255);"
            + "line-height: 40px;"
            + "text-align: center;"
            + "border-radius: 4px;"
            + "position: fixed;"
            + "top: 30%;"
            + "left: 50%;"
            + "transform: translate(-50%, -50%);"
            + "z-index: 9999999999;"
            + "background: rgba(0, 0, 0,.7);"
            + "font-size: 16px;";
        document.body.appendChild(m);
        setTimeout(function () {
            var d = 0.5;
            m.style.webkitTransition = '-webkit-transform ' + d + 's ease-in, opacity ' + d + 's ease-in';
            m.style.opacity = '0';
            setTimeout(function () {
                document.body.removeChild(m)
            }, d * 1000);
        }, duration);
    }

    function copySeedLink(content) {
        let transfer = document.createElement('input');
        document.body.appendChild(transfer);
        transfer.value = content + '\n';
        transfer.select();
        if (document.execCommand('copy')) {
            document.execCommand('copy');
        }
        document.body.removeChild(transfer);
        Toast('复制成功', 2000);
    }


    function createCopyButton(id) {
        let tmpImg = document.createElement("img");
        tmpImg.id = "copyButton";
        tmpImg.className = "download";
        tmpImg.style.cursor = "pointer";
        tmpImg.style.marginLeft = "4px";
        tmpImg.src = "CSS3 Menu_files/css3menu1/drawer.png";
        tmpImg.alt = "download";
        tmpImg.title = "复制链接";
        let seedLink = "https://hdarea.club/download.php?id=" + id + "&passkey=" + passkey;
        tmpImg.onclick = () => copySeedLink(seedLink);
        return tmpImg;
    }

    var seedtables = document.getElementsByClassName('torrents');

    var seedList = seedtables.length > 1 ? seedtables[1].children[0].children : seedtables[0].children[0].children

    for (let i = 1; i < seedList.length; i++) {
        let item = seedList[i];
        let buttonsTd = item.children[1].children[0].children[0].children[0].children[3];
        let id = item.children[1].children[0].children[0].children[0].children[3].getElementsByTagName('a')[0].href.split('=')[1];
        buttonsTd.appendChild(createCopyButton(id));
    }
})();