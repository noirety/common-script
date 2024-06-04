const passkey = "";

function getUrlParameter(url, paramName) {
    const urlObject = new URL(url);
    const urlParams = new URLSearchParams(urlObject.search);
    return urlParams.get(paramName);
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

    let downHashSet = new Set();
    let i = 0;

    for (let tempId of seedIdSet) {

        console.log(`正在获取第${i + 1}个种子链接`)
        try {
            downHashSet.add("https://pt.btschool.club/download.php?id=" + tempId + "&passkey=" + passkey);
        } catch (error) {
            console.error('Error:', error);
        }
        i++;
    }

    let downHashStr = Array.from(downHashSet).join('\n');
    console.log("获取种子链接执行完成");
    console.log(downHashStr);
}

await main();
