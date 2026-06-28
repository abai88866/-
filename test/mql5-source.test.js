import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const source = readFileSync('MQL5/Experts/K1_StopLossPoints.mq5', 'utf8');

test('MQL5 source exposes the requested EA inputs', () => {
  assert.match(source, /input string InpLotsSequence\s*=\s*"0\.3,0\.6,0\.9,1\.2,1\.5,1\.8,2\.1,2\.5"/);
  assert.match(source, /input long\s+InpMagicNumber\s*=\s*123456/);
  assert.match(source, /input int\s+InpSingleTakeProfitPoints\s*=\s*100/);
});

test('MQL5 source contains trading, grid, hedge, and chart panel handlers', () => {
  for (const symbol of ['OnTick', 'OnChartEvent', 'ManageGrid', 'ManageHedgeProfit', 'CreatePanel', 'DrawPositionLines']) {
    assert.ok(source.includes(symbol), `${symbol} should be present`);
  }
});
