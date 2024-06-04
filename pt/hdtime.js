let urlList = [
    'https://hdtime.org/details.php?id=82097',
    'https://hdtime.org/details.php?id=70671',
    'https://hdtime.org/details.php?id=55124',
    'https://hdtime.org/details.php?id=54856',
    'https://hdtime.org/details.php?id=40218',
    'https://hdtime.org/details.php?id=89427',
    'https://hdtime.org/details.php?id=77359',
    'https://hdtime.org/details.php?id=54717',
    'https://hdtime.org/details.php?id=55391',
    'https://hdtime.org/details.php?id=40310',
    'https://hdtime.org/details.php?id=87580',
    'https://hdtime.org/details.php?id=89494',
    'https://hdtime.org/details.php?id=43893',
    'https://hdtime.org/details.php?id=43894',
    'https://hdtime.org/details.php?id=79436',
    'https://hdtime.org/details.php?id=56874',
    'https://hdtime.org/details.php?id=82096',
    'https://hdtime.org/details.php?id=54520',
    'https://hdtime.org/details.php?id=19850',
    'https://hdtime.org/details.php?id=60562',
    'https://hdtime.org/details.php?id=84505',
    'https://hdtime.org/details.php?id=85500',
    'https://hdtime.org/details.php?id=40306',
    'https://hdtime.org/details.php?id=82239',
    'https://hdtime.org/details.php?id=90425',
    'https://hdtime.org/details.php?id=89598',
    'https://hdtime.org/details.php?id=40216',
    'https://hdtime.org/details.php?id=85035',
    'https://hdtime.org/details.php?id=88698',
    'https://hdtime.org/details.php?id=83014'
]

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
            let regex = /https:\/\/hdtime\.org\/download\.php\?downhash=[^\s'"]+/g;
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

    let iframe = document.createElement("iframe");
    iframe.style.display = "none";

    let downHashSet = new Set();
    let i = 0;

    for (let url of urlList) {

        console.log(`正在获取第${i + 1}个种子链接`)
        try {
            iframe.src = url;
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
