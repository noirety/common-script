function getUrlParameter(url, paramName) {
    const urlObject = new URL(url);
    const urlParams = new URLSearchParams(urlObject.search);
    return urlParams.get(paramName);
}

function loadIframeContent(iframe) {
    return new Promise((resolve, reject) => {
        iframe.onload = function () {
            let iframeWindow = iframe.contentWindow;
            let iframeDocument = iframeWindow.document;
            let title = iframeDocument.title;
            let content = iframeDocument.body.innerHTML;
            let regex = /https:\/\/cyanbug\.net\/download\.php\?downhash=[^\s'"]+/g;
            let matches = content.match(regex);
            if (matches) {
                resolve(matches);
            } else {
                reject('No matches found');
            }
        };
    });
}

async function main() {

    // 获取当前页面所有a标签
    let aTags = document.getElementsByClassName('torrents')[0]
        .children[0].getElementsByTagName('a');

    let seedIdSet = new Set();

    // 这个方法会获取到一条脏数据，后面慢慢研究。。
    for (let temp of aTags) {
        if (temp && temp.href.includes("details.php")) {
            let id = getUrlParameter(temp.href, "id")
            seedIdSet.add(id);
        }
    }

    let iframe = document.createElement("iframe");
    iframe.style.display = "none";

    let downHashSet = new Set();
    let i = 0;

    for (let tempId of seedIdSet) {

        console.log(`正在获取第${i + 1}个种子链接`)
        try {
            iframe.src = "https://cyanbug.net/details.php?id=" + tempId + "&hit=1";
            document.body.appendChild(iframe);
            let startTime = new Date();
            let tempUrl = await loadIframeContent(iframe);
            downHashSet.add(tempUrl);
            let endTime = new Date();
            let elapsedTime = endTime - startTime;
            console.log(`耗时: ${elapsedTime}毫秒`);
        } catch (error) {
            console.error('Error:', error);
        }
        i++;
    }

    document.body.removeChild(iframe);
    let downHashStr = Array.from(downHashSet).join('\n');
    console.log("获取种子链接执行完成");
    console.log(downHashStr);
}

await main();
