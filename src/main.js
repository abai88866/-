import { generateCandles, inputRows, orders } from './data.js';

let scroll = 0;
const root = document.getElementById('root');

function parameterRows() {
  return inputRows.slice(scroll, scroll + 12).map(row => `
    <div class="cell var"><span class="type">${row[0]}</span>${row[1]}</div>
    <div class="cell value">${row[2]}</div>`).join('');
}

function renderDialog() {
  return `<div class="dialog">
    <div class="dialog-title">K1_止损点数447053894 1.00 (XAUUSDc,M1)<span>— □ ×</span></div>
    <div class="tabs"><b>普通</b><b class="active">输入</b></div>
    <div class="dialog-body">
      <div class="grid"><div class="head">可变</div><div class="head">值</div>${parameterRows()}
        <input id="paramScroll" class="range" aria-label="滚动参数" type="range" min="0" max="${inputRows.length - 12}" value="${scroll}"></div>
      <div class="side"><button>载入(L)</button><button>保存(S)</button></div>
    </div>
    <div class="actions"><button class="primary">确定</button><button>取消</button><button>重置</button></div>
  </div>`;
}

function renderChart() {
  const candleSvg = generateCandles().map(c => `<g class="${c.close > c.open ? 'up' : 'down'} candle"><line x1="${c.x}" x2="${c.x}" y1="${c.high * 3.2}" y2="${c.low * 3.2}"/><rect x="${c.x - 5}" y="${Math.min(c.open,c.close)*3.2}" width="10" height="${Math.abs(c.close-c.open)*3.2 || 4}"/></g>`).join('');
  const orderText = orders.slice(0,5).map((o,i)=>`<text x="8" y="${86+i*72}">${o[0]} ${o[1]} at ${o[2]}</text>`).join('');
  const volumes = Array.from({length:60},(_,i)=>`<i style="height:${24 + (i*7)%52}px"></i>`).join('');
  return `<div class="terminal"><div class="menu">📊 文件(F)　查看(V)　插入(I)　图表(C)　工具(T)　窗口(W)　帮助(H)</div><div class="toolbar">↖︎ ⊕ ┃ ─ ╱ M1 M5 M15 M30 H1 H4 D1 W1 MN</div><div class="chart">
    <div class="panel"><button>SELL</button><input value="1.00"><button>BUY</button><div class="quote"><span>3991</span><b>28</b><sup>9</sup><span>3991</span><b>54</b><sup>9</sup></div></div>
    <svg viewBox="0 0 1000 560" preserveAspectRatio="none">
      ${[80,145,220,300,390].map(y=>`<line class="order" x1="0" x2="1000" y1="${y}" y2="${y}"/>`).join('')}
      ${[150,270,390].map((y,i)=>`<path class="ma blue" d="M0 ${y+i*12} C220 ${y-50}, 510 ${y+90}, 1000 ${210+i*55}"/>`).join('')}
      ${[360,430].map(y=>`<path class="ma red" d="M0 ${y} C250 ${y+40}, 620 ${y+15}, 1000 ${y-20}"/>`).join('')}
      ${candleSvg}${orderText}</svg><div class="trade"><button class="white">suocang</button><button>buy</button><button>sell</button></div><div class="volumes">${volumes}</div></div></div>`;
}

function render() {
  root.innerHTML = `<main>${renderChart()}${renderDialog()}</main>`;
  document.getElementById('paramScroll').addEventListener('input', event => { scroll = Number(event.target.value); render(); });
}

render();
