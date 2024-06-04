let urlList = [
    'https://rousi.zip/details.php?id=3322&hit=1',
    'https://rousi.zip/details.php?id=3324&hit=1',
    'https://rousi.zip/details.php?id=3325&hit=1',
    'https://rousi.zip/details.php?id=8739&hit=1',
    'https://rousi.zip/details.php?id=795&hit=1',
    'https://rousi.zip/details.php?id=796&hit=1',
    'https://rousi.zip/details.php?id=797&hit=1',
    'https://rousi.zip/details.php?id=794&hit=1',
    'https://rousi.zip/details.php?id=793&hit=1',
    'https://rousi.zip/details.php?id=792&hit=1',
    'https://rousi.zip/details.php?id=791&hit=1',
    'https://rousi.zip/details.php?id=790&hit=1',
    'https://rousi.zip/details.php?id=788&hit=1',
    'https://rousi.zip/details.php?id=3326&hit=1',
    'https://rousi.zip/details.php?id=789&hit=1',
    'https://rousi.zip/details.php?id=787&hit=1',
    'https://rousi.zip/details.php?id=9146&hit=1',
    'https://rousi.zip/details.php?id=9150&hit=1',
    'https://rousi.zip/details.php?id=9149&hit=1',
    'https://rousi.zip/details.php?id=9154&hit=1',
    'https://rousi.zip/details.php?id=3327&hit=1',
    'https://rousi.zip/details.php?id=3328&hit=1',
    'https://rousi.zip/details.php?id=8958&hit=1',
    'https://rousi.zip/details.php?id=10549&hit=1',
    'https://rousi.zip/details.php?id=3331&hit=1',
    'https://rousi.zip/details.php?id=15503&hit=1',
    'https://rousi.zip/details.php?id=18504&hit=1',
    'https://rousi.zip/details.php?id=3334&hit=1',
    'https://rousi.zip/details.php?id=8980&hit=1',
    'https://rousi.zip/details.php?id=3336&hit=1',
    'https://rousi.zip/details.php?id=8978&hit=1',
    'https://rousi.zip/details.php?id=8717&hit=1',
    'https://rousi.zip/details.php?id=3337&hit=1',
    'https://rousi.zip/details.php?id=3338&hit=1',
    'https://rousi.zip/details.php?id=15171&hit=1',
    'https://rousi.zip/details.php?id=813&hit=1',
    'https://rousi.zip/details.php?id=815&hit=1',
    'https://rousi.zip/details.php?id=816&hit=1',
    'https://rousi.zip/details.php?id=808&hit=1',
    'https://rousi.zip/details.php?id=8597&hit=1',
    'https://rousi.zip/details.php?id=809&hit=1',
    'https://rousi.zip/details.php?id=8716&hit=1',
    'https://rousi.zip/details.php?id=811&hit=1',
    'https://rousi.zip/details.php?id=237&hit=1',
    'https://rousi.zip/details.php?id=9846&hit=1',
    'https://rousi.zip/details.php?id=8963&hit=1',
    'https://rousi.zip/details.php?id=812&hit=1',
    'https://rousi.zip/details.php?id=8600&hit=1',
    'https://rousi.zip/details.php?id=2490&hit=1',
    'https://rousi.zip/details.php?id=2491&hit=1'
]


function loadIframeContent(iframe) {
    return new Promise((resolve, reject) => {
        iframe.onload = function () {
            let iframeWindow = iframe.contentWindow;
            let iframeDocument = iframeWindow.document;
            let title = iframeDocument.title;
            let content = iframeDocument.body.innerHTML;
            let regex = /https:\/\/rousi\.zip\/download\.php\?downhash=[^\s'"]+/g;
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

    let downhashSet = new Set();
    for (let i = 0; i < urlList.length; i++) {
        console.log(`正在获取第${i + 1}个种子链接`)
        try {
            iframe.src = urlList[i];
            document.body.appendChild(iframe);
            let startTime = new Date();
            let tempUrl = await loadIframeContent(iframe);
            downhashSet.add(tempUrl);
            let endTime = new Date();
            let elapsedTime = endTime - startTime;
            console.log(`耗时: ${elapsedTime}毫秒`);
        } catch (error) {
            console.error('Error:', error);
        }
    }
    document.body.removeChild(iframe);
    let downHashStr = Array.from(downhashSet).join('\n');
    console.log("获取种子链接执行完成");
    console.log(downHashStr);
}

main();