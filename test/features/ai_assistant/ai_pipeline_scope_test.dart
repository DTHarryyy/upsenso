import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/ai_pipeline.dart';
import 'package:pos/features/ai_assistant/services/ai_scope_guard.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';
import 'package:pos/features/ai_assistant/services/llm_service.dart';

class MockLlmService extends Mock implements LlmService {}

class MockAiToolService extends Mock implements AiToolService {}

class MockAiScopeGuard extends Mock implements AiScopeGuard {}

void main() {
  late MockLlmService llm;
  late MockAiToolService tool;
  late MockAiScopeGuard guard;
  late AiPipeline pipeline;

  const scope = AiScope(
    businessId: 'biz1',
    userId: 'u1',
    branchId: 'b1',
    ownUserId: 'u1',
    includeStock: true,
  );

  setUpAll(() => registerFallbackValue(const AiDateFilter()));

  setUp(() {
    llm = MockLlmService();
    tool = MockAiToolService();
    guard = MockAiScopeGuard();
    pipeline = AiPipeline(
      llmService: llm,
      toolService: tool,
      scopeGuard: guard,
    );
  });

  test('a denied read never touches the tool layer', () async {
    when(
      () => llm.generateResponse(any()),
    ).thenAnswer((_) async => '{"action": "GET_SALES"}');
    when(() => guard.authorizeRead(AiAction.getSales)).thenReturn(
      const AiScopeResult.deny("You don't have access to sales reports."),
    );

    final result = await pipeline.processMessage(userMessage: 'sales today');

    expect(result.responseText, "You don't have access to sales reports.");
    verify(() => guard.authorizeRead(AiAction.getSales)).called(1);
    verifyNever(
      () => tool.getSalesTotal(
        any(),
        any(),
        any(),
        branchId: any(named: 'branchId'),
        ownUserId: any(named: 'ownUserId'),
      ),
    );
  });

  test('an allowed read runs with the guard-resolved scope injected', () async {
    when(
      () => llm.generateResponse(any()),
    ).thenAnswer((_) async => '{"action": "GET_SALES"}');
    when(
      () => guard.authorizeRead(AiAction.getSales),
    ).thenReturn(const AiScopeResult.allow());
    when(() => guard.resolveScope()).thenReturn(scope);
    when(
      () => tool.getSalesTotal(
        any(),
        any(),
        any(),
        branchId: any(named: 'branchId'),
        ownUserId: any(named: 'ownUserId'),
      ),
    ).thenAnswer((_) async => 1234.0);

    final result = await pipeline.processMessage(userMessage: 'sales today');

    // The own-user + branch filters from the resolved scope reach the query.
    verify(
      () => tool.getSalesTotal(
        'biz1',
        'u1',
        any(),
        branchId: 'b1',
        ownUserId: 'u1',
      ),
    ).called(1);
    expect(result.responseText, contains('1,234'));
  });

  test('a denied sale-create never reaches checkout', () async {
    when(() => llm.generateResponse(any())).thenAnswer(
      (_) async =>
          '{"action": "CREATE_TRANSACTION", '
          '"items": [{"name": "coke", "quantity": 2}]}',
    );
    when(
      () => guard.authorizeWrite(AiAction.createTransaction),
    ).thenAnswer((_) async => const AiScopeResult.deny('no pos.use'));

    final result = await pipeline.processMessage(userMessage: '2 coke');

    expect(result.responseText, 'no pos.use');
    verify(() => guard.authorizeWrite(AiAction.createTransaction)).called(1);
    verifyNever(() => tool.getProductCatalog(any()));
  });
}
