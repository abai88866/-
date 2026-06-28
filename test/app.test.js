import test from 'node:test';
import assert from 'node:assert/strict';
import { inputRows, orders, generateCandles } from '../src/data.js';

test('contains copied EA inputs and order labels', () => {
  assert.equal(inputRows[0][1], '等分下单手数');
  assert.equal(inputRows.find(row => row[1] === 'EA识别码')[2], '123456');
  assert.ok(orders.some(order => order.join(' ') === 'BUY 0.4 3997.315'));
});

test('generates candles for the chart mock', () => {
  const candles = generateCandles();
  assert.equal(candles.length, 62);
  assert.ok(candles.every(c => c.high >= c.open && c.high >= c.close));
});
