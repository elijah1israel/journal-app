import 'package:flutter_test/flutter_test.dart';
import 'package:wickbook/models/auth_user.dart';
import 'package:wickbook/models/strategy.dart';
import 'package:wickbook/models/trade.dart';

void main() {
  group('AuthUser', () {
    test('parses /traders/me/ payload', () {
      final u = AuthUser.fromJson({
        'id': 7,
        'email': 'lyn@example.com',
        'first_name': 'Lyn',
        'last_name': 'Trader',
        'bio': '',
        'experience_level': 'advanced',
        'preferred_markets': 'Forex,Gold',
        'timezone': 'Africa/Lagos',
      });
      expect(u.id, 7);
      expect(u.displayName, 'Lyn Trader');
      expect(u.initials, 'LT');
      expect(u.experienceLevel, 'advanced');
    });

    test('falls back to email when name is empty', () {
      final u = AuthUser.fromJson({'id': 1, 'email': 'x@y.com'});
      expect(u.displayName, 'x@y.com');
      expect(u.initials, 'X');
    });
  });

  group('TradeDirection / TradeResult', () {
    test('round-trip through wire format', () {
      expect(TradeDirection.fromWire('buy'), TradeDirection.buy);
      expect(TradeDirection.fromWire('sell'), TradeDirection.sell);
      expect(TradeDirection.fromWire('weird'), TradeDirection.buy);
      expect(TradeResult.fromWire(''), TradeResult.none);
      expect(TradeResult.fromWire('tp'), TradeResult.tp);
      expect(TradeResult.fromWire('sl'), TradeResult.sl);
    });

    test('labels are user-friendly', () {
      expect(TradeDirection.buy.label, 'Long');
      expect(TradeDirection.sell.label, 'Short');
      expect(TradeResult.tp.label, 'TP');
      expect(TradeResult.none.label, 'Open');
    });
  });

  group('Trade.fromJson', () {
    test('parses a closed winning trade with computed fields', () {
      final t = Trade.fromJson({
        'id': 42,
        'strategy': 3,
        'strategy_name': 'FVG + LQ sweep',
        'symbol': 'EURUSD',
        'direction': 'buy',
        'status': 'closed',
        'result': 'tp',
        'position_size': '1.00',
        'contract_size': '100000',
        'entry_price': '1.09250',
        'exit_price': '1.09500',
        'stop_loss': '1.09100',
        'take_profit': '1.09500',
        'entry_date': '2026-06-01T08:00:00Z',
        'exit_date': '2026-06-01T11:30:00Z',
        'pnl': '250.00',
        'pnl_pct': '0.23',
        'risk_reward': '1.67',
        'notes': 'Clean reaction off the sweep.',
        'tags': 'london,sweep',
      });
      expect(t.id, 42);
      expect(t.direction, TradeDirection.buy);
      expect(t.status, TradeStatus.closed);
      expect(t.result, TradeResult.tp);
      expect(t.isWinner, isTrue);
      expect(t.isLoser, isFalse);
      expect(t.entryPrice, closeTo(1.09250, 1e-9));
      expect(t.pnl, 250.0);
      expect(t.riskReward, closeTo(1.67, 1e-9));
      expect(t.strategyName, 'FVG + LQ sweep');
    });

    test('treats missing exit fields as open', () {
      final t = Trade.fromJson({
        'id': 1,
        'symbol': 'XAUUSD',
        'direction': 'sell',
        'status': 'open',
        'result': '',
        'position_size': '0.5',
        'entry_price': '2400.00',
        'entry_date': '2026-06-10T07:00:00Z',
      });
      expect(t.isOpen, isTrue);
      expect(t.result, TradeResult.none);
      expect(t.exitPrice, isNull);
      expect(t.pnl, isNull);
    });
  });

  group('Strategy.fromJson', () {
    test('splits comma-separated timeframes and markets', () {
      final s = Strategy.fromJson({
        'id': 9,
        'name': 'LQ sweep',
        'description': 'Liquidity sweep + FVG continuation',
        'rules': '1. Wait for sweep\n2. Confirm FVG',
        'timeframes': 'M15,H1,H4',
        'markets': 'Forex,Gold',
      });
      expect(s.name, 'LQ sweep');
      expect(s.timeframeList, ['M15', 'H1', 'H4']);
      expect(s.marketList, ['Forex', 'Gold']);
    });

    test('handles blank timeframes / markets', () {
      final s = Strategy.fromJson(
          {'id': 1, 'name': 'x', 'timeframes': '', 'markets': ''});
      expect(s.timeframeList, isEmpty);
      expect(s.marketList, isEmpty);
    });
  });
}
