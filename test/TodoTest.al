codeunit 50112 "APSS Todo Test"
{
    procedure TestInvalidTodoHandling()
    var
        TempExternalTodo: Record "APSS External Todo" temporary;
        JsonArrayParser: Codeunit "APSS Json Array Parser";
        JsonResponse: Text;
        ProcessedCount: Integer;
        SuccessfulCount: Integer;
        FailedCount: Integer;
        ResultMessage: Text;
    begin
        JsonResponse :=
            '[' +
            '{"userId":1,"id":1,"title":"Todo 1","completed":false},' +
            '{"userId":1,"id":2,"title":"Todo 2","completed":false},' +
            '{"userId":1,"id":3,"title":null,"completed":false},' +
            '{"userId":1,"id":4,"title":"Todo 4","completed":false}' +
            ']';

        if not JsonArrayParser.ParseTodoArray(
            JsonResponse,
            TempExternalTodo,
            ProcessedCount,
            SuccessfulCount,
            FailedCount)
        then begin
            Message(
                'Test failed: the JSON response could not be processed.');

            exit;
        end;

        ResultMessage :=
            StrSubstNo(
                'Test result:\Processed: %1\Successful: %2\Failed: %3\',
                ProcessedCount,
                SuccessfulCount,
                FailedCount);

        if ProcessedCount <> 4 then
            ResultMessage +=
                'FAILED: Expected 4 processed records.\';

        if SuccessfulCount <> 3 then
            ResultMessage +=
                'FAILED: Expected 3 successful records.\';

        if FailedCount <> 1 then
            ResultMessage +=
                'FAILED: Expected 1 failed record.\';

        if not TempExternalTodo.Get(1) then
            ResultMessage +=
                'FAILED: Todo 1 was not processed.\';

        if not TempExternalTodo.Get(2) then
            ResultMessage +=
                'FAILED: Todo 2 was not processed.\';

        if TempExternalTodo.Get(3) then
            ResultMessage +=
                'FAILED: Invalid Todo 3 was incorrectly inserted.\';

        if not TempExternalTodo.Get(4) then
            ResultMessage +=
                'FAILED: Todo 4 was not processed after invalid Todo 3.\';

        if
            (ProcessedCount = 4) and
            (SuccessfulCount = 3) and
            (FailedCount = 1) and
            TempExternalTodo.Get(1) and
            TempExternalTodo.Get(2) and
            not TempExternalTodo.Get(3) and
            TempExternalTodo.Get(4)
        then
            ResultMessage +=
                'PASS: Invalid Todo was logged/skipped and processing continued.';

        Message(ResultMessage);
    end;
}