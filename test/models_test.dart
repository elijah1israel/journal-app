import 'package:flutter_test/flutter_test.dart';
import 'package:wickbook/models/auth_user.dart';
import 'package:wickbook/models/community.dart';
import 'package:wickbook/models/csv_import_result.dart';
import 'package:wickbook/models/strategy.dart';
import 'package:wickbook/models/trade.dart';
import 'package:wickbook/models/trade_plan.dart';

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

  group('CsvImportResult.fromJson', () {
    test('parses the broker-sync summary', () {
      final r = CsvImportResult.fromJson({
        'created': 12,
        'updated': 3,
        'skipped': 47,
        'total_in_file': 62,
      });
      expect(r.created, 12);
      expect(r.updated, 3);
      expect(r.skipped, 47);
      expect(r.totalInFile, 62);
      expect(r.processed, 62);
    });

    test('defaults missing fields to zero', () {
      final r = CsvImportResult.fromJson({});
      expect(r.created, 0);
      expect(r.updated, 0);
      expect(r.skipped, 0);
      expect(r.totalInFile, 0);
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

  group('Community.fromJson', () {
    test('parses a community with tiers and viewer membership', () {
      final c = Community.fromJson({
        'id': 7,
        'slug': 'pip-hunters',
        'name': 'Pip Hunters',
        'tagline': 'Daily forex calls',
        'description': '',
        'currency': 'UGX',
        'owner': 3,
        'owner_name': 'Joy G.',
        'member_count': 124,
        'cover_image': null,
        'avatar': null,
        'is_owner': false,
        'tiers': [
          {'id': 1, 'community': 7, 'name': 'Free', 'price': '0.00',
           'interval': 'month', 'is_active': true, 'description': ''},
          {'id': 2, 'community': 7, 'name': 'VIP', 'price': '20000.00',
           'interval': 'month', 'is_active': true, 'description': ''},
        ],
        'my_membership': {
          'id': 42, 'tier_id': 1, 'tier_name': 'Free',
          'status': 'active', 'is_active': true,
        },
      });
      expect(c.name, 'Pip Hunters');
      expect(c.tiers.length, 2);
      expect(c.tiers.first.isFree, isTrue);
      expect(c.hasPaidTier, isTrue);
      expect(c.isMember, isTrue);
      expect(c.isOwner, isFalse);
      expect(c.myMembership?.tierName, 'Free');
    });

    test('treats missing my_membership as not joined', () {
      final c = Community.fromJson({
        'id': 1, 'slug': 'x', 'name': 'X', 'tagline': '', 'description': '',
        'currency': 'KES', 'owner': 1, 'owner_name': '',
        'member_count': 0, 'tiers': [], 'my_membership': null,
        'is_owner': false,
      });
      expect(c.myMembership, isNull);
      expect(c.isMember, isFalse);
      expect(c.hasPaidTier, isFalse);
    });
  });

  group('Strategy checklist', () {
    test('parses embedded rules into StrategyRule rows', () {
      final s = Strategy.fromJson({
        'id': 1, 'name': 'LQ', 'description': '', 'rules': '',
        'timeframes': '', 'markets': '',
        'checklist': [
          {'id': 11, 'text': 'HTF bias agrees', 'is_required': true, 'order': 0},
          {'id': 12, 'text': 'Sweep + FVG', 'is_required': true, 'order': 1},
          {'id': 13, 'text': 'London session', 'is_required': false, 'order': 2},
        ],
      });
      expect(s.checklist.length, 3);
      expect(s.checklist.first.text, 'HTF bias agrees');
      expect(s.checklist.last.isRequired, isFalse);
    });

    test('defaults to empty checklist when missing', () {
      final s = Strategy.fromJson({'id': 1, 'name': 'x'});
      expect(s.checklist, isEmpty);
    });
  });

  group('TradePlan + DisciplineStats', () {
    test('TradePlan parses planned prices and decision', () {
      final p = TradePlan.fromJson({
        'id': 7,
        'strategy': 1,
        'symbol': 'EURUSD',
        'direction': 'buy',
        'planned_entry': '1.0850',
        'planned_sl': '1.0820',
        'planned_tp': '1.0910',
        'planned_size': '1',
        'decision': 'take',
        'override_reason': '',
        'notes': '',
        'checks': [
          {'rule': 11, 'rule_text': 'HTF bias', 'is_required': true, 'checked': true},
          {'rule': 12, 'rule_text': 'Sweep + FVG', 'is_required': true, 'checked': true},
        ],
        'required_rules_followed': true,
        'created_at': '2026-06-19T10:00:00Z',
        'decided_at': '2026-06-19T10:05:00Z',
      });
      expect(p.decision, PlanDecision.take);
      expect(p.plannedEntry, 1.0850);
      expect(p.checks.length, 2);
      expect(p.requiredRulesFollowed, isTrue);
    });

    test('DisciplineStats reports hasComparison only with both buckets', () {
      final solo = DisciplineStats.fromJson({
        'closed_trades_total': 5, 'planned_trades_total': 5, 'planning_rate': 100,
        'followed': {'count': 5, 'win_rate': 60, 'total_pnl': 300},
        'broken':   {'count': 0, 'win_rate': null, 'total_pnl': 0},
      });
      expect(solo.hasComparison, isFalse);

      final both = DisciplineStats.fromJson({
        'closed_trades_total': 10, 'planned_trades_total': 8, 'planning_rate': 80,
        'followed': {'count': 6, 'win_rate': 67, 'total_pnl': 400},
        'broken':   {'count': 2, 'win_rate': 0,  'total_pnl': -120},
      });
      expect(both.hasComparison, isTrue);
      expect(both.followedWinRate, 67);
      expect(both.brokenPnl, -120);
    });
  });

  group('GuardrailStatus', () {
    test('parses active block payload', () {
      final s = GuardrailStatus.fromJson({
        'daily_pnl': -150.0,
        'daily_loss_limit': '100.00',
        'daily_loss_limit_hit': true,
        'cool_down_minutes': 30,
        'cool_down_until': null,
        'can_trade': false,
        'block_reason': 'Daily loss limit reached.',
      });
      expect(s.canTrade, isFalse);
      expect(s.dailyLossLimit, 100);
      expect(s.dailyLossLimitHit, isTrue);
    });

    test('parses unblocked payload with no limit set', () {
      final s = GuardrailStatus.fromJson({
        'daily_pnl': 0,
        'daily_loss_limit': null,
        'daily_loss_limit_hit': false,
        'cool_down_minutes': 0,
        'cool_down_until': null,
        'can_trade': true,
        'block_reason': '',
      });
      expect(s.canTrade, isTrue);
      expect(s.dailyLossLimit, isNull);
      expect(s.blockReason, isEmpty);
    });
  });

  group('TradeCall', () {
    test('parses an active call with all TPs and status helpers', () {
      final c = TradeCall.fromJson({
        'id': 1, 'instrument': 'EURUSD', 'direction': 'long',
        'entry': '1.0850', 'stop_loss': '1.0820',
        'take_profit_1': '1.0890', 'take_profit_2': '1.0930',
        'take_profit_3': null,
        'risk_pct': '0.50', 'status': 'active',
        'closed_at': null, 'closed_pnl_pips': null,
      });
      expect(c.isOpen, isTrue);
      expect(c.isWinner, isFalse);
      expect(c.takeProfit2, 1.0930);
      expect(c.takeProfit3, isNull);
      expect(c.statusLabel, 'Active');
    });

    test('flags a TP-hit call as winner and surfaces realised pips', () {
      final c = TradeCall.fromJson({
        'id': 2, 'instrument': 'XAUUSD', 'direction': 'short',
        'entry': '2400', 'stop_loss': '2410', 'take_profit_1': '2380',
        'status': 'tp1_hit',
        'closed_at': '2026-06-19T15:00:00Z',
        'closed_pnl_pips': '20.0',
      });
      expect(c.isWinner, isTrue);
      expect(c.isOpen, isFalse);
      expect(c.closedPnlPips, 20.0);
      expect(c.statusLabel, 'TP1 hit');
    });
  });

  group('AuthUser guardrails', () {
    test('parses daily_loss_limit + cool_down_minutes_after_loss', () {
      final u = AuthUser.fromJson({
        'id': 1, 'email': 'g@x.io',
        'first_name': 'Joy', 'last_name': 'G',
        'experience_level': 'intermediate', 'timezone': 'Africa/Kampala',
        'daily_loss_limit': '200.00',
        'cool_down_minutes_after_loss': 30,
      });
      expect(u.dailyLossLimit, 200);
      expect(u.coolDownMinutesAfterLoss, 30);
    });

    test('defaults guardrails to disabled when missing', () {
      final u = AuthUser.fromJson({
        'id': 1, 'email': 'x@y.io',
      });
      expect(u.dailyLossLimit, isNull);
      expect(u.coolDownMinutesAfterLoss, 0);
    });
  });
}
