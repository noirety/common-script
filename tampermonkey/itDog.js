// ==UserScript==
// @name         IPDog禁止弹窗
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.itdog.cn/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=tampermonkey.net
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // 屏蔽弹窗
    window.alert = function (str) {
        return ;
    };

    var divs = document.getElementsByTagName("header");

    // 屏蔽头部广告
    for (var i = divs.length - 1; i >= 0; i--) {
        var div = divs[i];
        div.remove();
    }
})();