const searchUrl = "https://api.m-team.io/api/torrent/search";
const historyUrl = "https://api.m-team.io/api/tracker/queryHistory";
const seedLinkUrl = "https://api.m-team.io/api/torrent/genDlToken";
const downloadPrefix = "https://api.m-team.io/api/rss/dlv2";
// 种子从小到大排序，获取从第几页到第几页的种子链接
const startPage = 17;
const endPage = 47;
// -1不限制获取条数，根据页数来，其他正值，限制获取种子数
const getSeedNum = -1;

const Authorization=""

// 25%加成官种：https://kp.m-team.cc/detail/112036

/**
 * 生成指定范围内的随机数
 * @param min
 * @param max
 * @returns {*}
 */
function getRandomNumber(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * 随机数delay
 * @param num
 * @returns {Promise<unknown>}
 */
function randDelay(num) {
    const randomNum = getRandomNumber(-2000, 2000);
    let ms = Math.abs(num + randomNum);
    return new Promise(resolve => setTimeout(resolve, ms));
}

function getMTeamSeedListSync(pageNum) {
    let requestBody = {
        mode: "normal",
        categories: [],
        visible: 1,
        sortDirection: "ASC",
        sortField: "SIZE",
        pageNumber: pageNum,
        pageSize: 100
    }

    const xhr = new XMLHttpRequest();
    // 将第三个参数设置为 false 以使请求同步
    xhr.open('POST', searchUrl, false);
    // 如果需要设置请求头或其他配置,可以在此处进行
    xhr.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
    xhr.setRequestHeader('Authorization', Authorization);
    xhr.send(JSON.stringify(requestBody));

    if (xhr.status === 200) {
        // 返回响应的种子列表
        return JSON.parse(xhr.responseText).data.data;
    } else {
        throw new Error('Request failed with status ' + xhr.status);
    }
}

function getMTeamSeedHistorySync(tids) {
    let requestBody = {
        tids: tids
    }
    const xhr = new XMLHttpRequest();
    // 将第三个参数设置为 false 以使请求同步
    xhr.open('POST', historyUrl, false);
    // 如果需要设置请求头或其他配置,可以在此处进行
    xhr.setRequestHeader('Content-Type', 'application/json;charset=UTF-8');
    xhr.setRequestHeader('Authorization', Authorization);
    xhr.send(JSON.stringify(requestBody));

    if (xhr.status === 200) {
        let peerMap = JSON.parse(xhr.responseText).data.peerMap;
        return Array.from(Object.keys(peerMap));
    } else {
        throw new Error('Request failed with status ' + xhr.status);
    }
}

/**
 * 根据id获取种子下载链接
 * @param id
 * @returns {*}
 */
function getDownloadUrlSync(id) {
    const formData = new FormData();
    formData.append('id', id);

    const xhr = new XMLHttpRequest();
    // 将第三个参数设置为 false 以使请求同步
    xhr.open('POST', seedLinkUrl, false);
    xhr.setRequestHeader('Authorization', Authorization);
    xhr.send(formData);

    if (xhr.status === 200) {
        // 返回响应文本
        return JSON.parse(xhr.responseText).data;
    } else {
        throw new Error('Request failed with status ' + xhr.status);
    }
}

async function main() {
    let linkSet = new Set();
    try {
        let seedNum = 1;
        for (let i = startPage; i < endPage; i++) {
            console.log("正在获取第" + i + "页种子");
            let seedList = getMTeamSeedListSync(i);
            let tids = seedList.map(item => item.id);
            let seedingList = getMTeamSeedHistorySync(tids);

            for (let tempSeed of seedList) {
                let id = tempSeed.id;
                // 种子大小
                let size = tempSeed.size;
                // 做种人数
                let seeders = tempSeed.status.seeders;
                // 是否有官种魔力加成，会稀释高加成种
                let msUp = tempSeed.msUp;
                // 是否正在下载或者已下载完成
                let isDown = seedingList.includes(id);
                // 促销状态：NORMAL 无促销 PERCENT_50 50%下载 FREE 免费下载
                let discount = tempSeed.status.discount;
                // 过滤已下载种、死种、小于5M的种、官种
                if (!isDown && size > 5 * 1024 * 1024 && seeders > 10 && (msUp === 0 || msUp === 25)) {
                    console.log("正在获取第" + seedNum + "条下载链接...")
                    let link = getDownloadUrlSync(id);
                    if (link && link.startsWith(downloadPrefix)) {
                        linkSet.add(link);
                    }else {
                        throw "获取链接出错: "+link;
                    }
                    // 暂停一定时间，不然会获取频繁
                    await randDelay(2200);
                } else {
                    console.log("第" + seedNum + "条不符合条件，跳过")
                }
                // 限制获取条目
                if (getSeedNum > 0 && linkSet.size > getSeedNum) {
                    break;
                }
                seedNum++;
            }
        }
    } catch (err) {
        console.error('出现错误:', err.message);
    } finally {
        console.log("处理结束，获取到" + linkSet.size + "条")
        console.log(Array.from(linkSet).join('\n'));
    }
}

await main();
