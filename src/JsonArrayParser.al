codeunit 50101 "APSS Json Array Parser"
{
    /// <summary>
    /// Parses a JSON array of Todo records.
    /// Valid Todo records are added to the temporary buffer.
    /// Invalid Todo records are logged and skipped.
    /// </summary>
    procedure ParseTodoArray(
        JsonArrayText: Text;
        var TempExternalTodo: Record "APSS External Todo" temporary;
        var ProcessedCount: Integer;
        var SuccessfulCount: Integer;
        var FailedCount: Integer): Boolean
    var
        RootToken: JsonToken;
        JArray: JsonArray;
        JToken: JsonToken;
        JObject: JsonObject;
        APIErrorLogMgt: Codeunit "APSS API Error Log Mgt.";
        ArrayIndex: Integer;
        RecordReadSuccessfully: Boolean;
    begin
        Clear(ProcessedCount);
        Clear(SuccessfulCount);
        Clear(FailedCount);

        TempExternalTodo.Reset();
        TempExternalTodo.DeleteAll();

        if JsonArrayText.Trim() = '' then begin
            APIErrorLogMgt.LogValidationError(
                'JSONPlaceholder Todos',
                'The Todo response is empty.',
                0);

            exit(false);
        end;

        if not RootToken.ReadFrom(JsonArrayText) then begin
            APIErrorLogMgt.LogValidationError(
                'JSONPlaceholder Todos',
                'The Todo response contains invalid JSON.',
                0);

            exit(false);
        end;

        if not RootToken.IsArray() then begin
            APIErrorLogMgt.LogValidationError(
                'JSONPlaceholder Todos',
                'The Todo response must be a top-level JSON array.',
                0);

            exit(false);
        end;

        JArray := RootToken.AsArray();

        if JArray.Count() = 0 then begin
            APIErrorLogMgt.LogValidationError(
                'JSONPlaceholder Todos',
                'The Todo response contains no Todo records.',
                0);

            exit(false);
        end;

        for ArrayIndex := 0 to JArray.Count() - 1 do begin
            ProcessedCount += 1;
            RecordReadSuccessfully := false;

            if JArray.Get(
                ArrayIndex,
                JToken)
            then begin
                RecordReadSuccessfully := true;

                if not JToken.IsObject() then begin
                    APIErrorLogMgt.LogValidationError(
                        'JSONPlaceholder Todos',
                        StrSubstNo(
                            'Todo record at array index %1 must be a JSON object.',
                            ArrayIndex),
                        0);

                    FailedCount += 1;
                    RecordReadSuccessfully := false;
                end;

                if RecordReadSuccessfully then begin
                    JObject := JToken.AsObject();

                    if ProcessTodoRecord(
                        JObject,
                        ArrayIndex,
                        TempExternalTodo)
                    then
                        SuccessfulCount += 1
                    else
                        FailedCount += 1;
                end;
            end else begin
                APIErrorLogMgt.LogValidationError(
                    'JSONPlaceholder Todos',
                    StrSubstNo(
                        'Unable to read Todo record at array index %1.',
                        ArrayIndex),
                    0);

                FailedCount += 1;
            end;
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates one Todo record and adds it to the temporary buffer
    /// when validation succeeds. Invalid records are logged and skipped.
    /// </summary>
    local procedure ProcessTodoRecord(
        JObject: JsonObject;
        ArrayIndex: Integer;
        var TempExternalTodo: Record "APSS External Todo" temporary): Boolean
    var
        ExternalTodoID: Integer;
        ExternalUserID: Integer;
        Title: Text;
        Completed: Boolean;
        ErrorMessage: Text;
        APIErrorLogMgt: Codeunit "APSS API Error Log Mgt.";
    begin
        Clear(ExternalTodoID);
        Clear(ExternalUserID);
        Clear(Title);
        Clear(Completed);
        ClearLastError();

        if not TryValidateTodo(
            JObject,
            ArrayIndex,
            ExternalTodoID,
            ExternalUserID,
            Title,
            Completed)
        then begin
            ErrorMessage := GetLastErrorText();

            if ErrorMessage = '' then
                ErrorMessage :=
                    StrSubstNo(
                        'Todo record at array index %1 contains invalid data.',
                        ArrayIndex);

            APIErrorLogMgt.LogValidationError(
                'JSONPlaceholder Todos',
                ErrorMessage,
                ExternalTodoID);

            exit(false);
        end;

        if TempExternalTodo.Get(ExternalTodoID) then begin
            APIErrorLogMgt.LogValidationError(
                'JSONPlaceholder Todos',
                StrSubstNo(
                    'Todo record at array index %1 has duplicate id %2.',
                    ArrayIndex,
                    ExternalTodoID),
                ExternalTodoID);

            exit(false);
        end;

        InsertTodoToTemporaryBuffer(
            TempExternalTodo,
            ExternalTodoID,
            ExternalUserID,
            Title,
            Completed);

        exit(true);
    end;

    /// <summary>
    /// Validates all required fields of one Todo record.
    /// </summary>
    [TryFunction]
    local procedure TryValidateTodo(
        JObject: JsonObject;
        ArrayIndex: Integer;
        var ExternalTodoID: Integer;
        var ExternalUserID: Integer;
        var Title: Text;
        var Completed: Boolean)
    begin
        ExternalUserID :=
            GetRequiredPositiveInteger(
                JObject,
                'userId',
                ArrayIndex);

        ExternalTodoID :=
            GetRequiredPositiveInteger(
                JObject,
                'id',
                ArrayIndex);

        Title :=
            GetRequiredTitle(
                JObject,
                ArrayIndex,
                250);

        Completed :=
            GetRequiredBoolean(
                JObject,
                'completed',
                ArrayIndex);
    end;

    /// <summary>
    /// Inserts a validated Todo into the temporary synchronization buffer.
    /// </summary>
    local procedure InsertTodoToTemporaryBuffer(
        var TempExternalTodo: Record "APSS External Todo" temporary;
        ExternalTodoID: Integer;
        ExternalUserID: Integer;
        Title: Text;
        Completed: Boolean)
    begin
        TempExternalTodo.Init();
        TempExternalTodo."External Todo ID" := ExternalTodoID;
        TempExternalTodo."External User ID" := ExternalUserID;
        TempExternalTodo.Title := Title;
        TempExternalTodo.Completed := Completed;
        TempExternalTodo.Insert();
    end;

    /// <summary>
    /// Gets a required positive integer property from a Todo object.
    /// </summary>
    local procedure GetRequiredPositiveInteger(
        JObject: JsonObject;
        PropertyName: Text;
        ArrayIndex: Integer): Integer
    var
        ValueToken: JsonToken;
        Value: JsonValue;
        IntegerValue: Integer;
    begin
        GetRequiredValueToken(
            JObject,
            PropertyName,
            ArrayIndex,
            ValueToken);

        Value := ValueToken.AsValue();

        if Value.IsNull() then
            Error(
                'Todo record at array index %1 has a null %2 value.',
                ArrayIndex,
                PropertyName);

        if not TryGetInteger(
            Value,
            IntegerValue)
        then
            Error(
                'Todo record at array index %1 has a non-integer %2 value.',
                ArrayIndex,
                PropertyName);

        if IntegerValue <= 0 then
            Error(
                'Todo record at array index %1 must have a positive %2 value.',
                ArrayIndex,
                PropertyName);

        exit(IntegerValue);
    end;

    /// <summary>
    /// Attempts to convert a JSON value to an Integer.
    /// </summary>
    [TryFunction]
    local procedure TryGetInteger(
        Value: JsonValue;
        var IntegerValue: Integer)
    begin
        IntegerValue := Value.AsInteger();
    end;

    /// <summary>
    /// Gets and validates the required Todo title.
    /// </summary>
    local procedure GetRequiredTitle(
        JObject: JsonObject;
        ArrayIndex: Integer;
        MaximumLength: Integer): Text
    var
        ValueToken: JsonToken;
        Value: JsonValue;
        Title: Text;
    begin
        GetRequiredValueToken(
            JObject,
            'title',
            ArrayIndex,
            ValueToken);

        Value := ValueToken.AsValue();

        if Value.IsNull() then
            Error(
                'Todo record at array index %1 has a null title value.',
                ArrayIndex);

        if not TryGetText(
            Value,
            Title)
        then
            Error(
                'Todo record at array index %1 has a non-text title value.',
                ArrayIndex);

        if Title.Trim() = '' then
            Error(
                'Todo record at array index %1 has an empty title.',
                ArrayIndex);

        if StrLen(Title) > MaximumLength then
            Error(
                'Todo record at array index %1 has a title longer than %2 characters.',
                ArrayIndex,
                MaximumLength);

        exit(Title);
    end;

    /// <summary>
    /// Attempts to convert a JSON value to Text.
    /// </summary>
    [TryFunction]
    local procedure TryGetText(
        Value: JsonValue;
        var TextValue: Text)
    begin
        TextValue := Value.AsText();
    end;

    /// <summary>
    /// Gets and validates the required Todo completion status.
    /// </summary>
    local procedure GetRequiredBoolean(
        JObject: JsonObject;
        PropertyName: Text;
        ArrayIndex: Integer): Boolean
    var
        ValueToken: JsonToken;
        Value: JsonValue;
        BooleanValue: Boolean;
    begin
        GetRequiredValueToken(
            JObject,
            PropertyName,
            ArrayIndex,
            ValueToken);

        Value := ValueToken.AsValue();

        if Value.IsNull() then
            Error(
                'Todo record at array index %1 has a null %2 value.',
                ArrayIndex,
                PropertyName);

        if not TryGetBoolean(
            Value,
            BooleanValue)
        then
            Error(
                'Todo record at array index %1 has a non-Boolean %2 value.',
                ArrayIndex,
                PropertyName);

        exit(BooleanValue);
    end;

    /// <summary>
    /// Attempts to convert a JSON value to Boolean.
    /// </summary>
    [TryFunction]
    local procedure TryGetBoolean(
        Value: JsonValue;
        var BooleanValue: Boolean)
    begin
        BooleanValue := Value.AsBoolean();
    end;

    /// <summary>
    /// Gets a required scalar property from a Todo JSON object.
    /// </summary>
    local procedure GetRequiredValueToken(
        JObject: JsonObject;
        PropertyName: Text;
        ArrayIndex: Integer;
        var ValueToken: JsonToken)
    begin
        if not JObject.Get(
            PropertyName,
            ValueToken)
        then
            Error(
                'Todo record at array index %1 is missing required property %2.',
                ArrayIndex,
                PropertyName);

        if not ValueToken.IsValue() then
            Error(
                'Todo record at array index %1 has a non-scalar %2 value.',
                ArrayIndex,
                PropertyName);
    end;
}