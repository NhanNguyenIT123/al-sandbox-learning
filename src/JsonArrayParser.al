codeunit 50101 "APSS Json Array Parser"
{
    procedure ParseTodoArray(
        JsonArrayText: Text;
        var TempExternalTodo: Record "APSS External Todo" temporary)
    var
        RootToken: JsonToken;
        JArray: JsonArray;
        JToken: JsonToken;
        JObject: JsonObject;
        i: Integer;
    begin
        if JsonArrayText.Trim() = '' then
            Error('The Todo response is empty.');

        if not RootToken.ReadFrom(JsonArrayText) then
            Error('The Todo response contains invalid JSON.');

        if not RootToken.IsArray() then
            Error('The Todo response must be a top-level JSON array.');

        JArray := RootToken.AsArray();

        if JArray.Count() = 0 then
            Error('The Todo response contains no Todo records.');

        TempExternalTodo.Reset();
        TempExternalTodo.DeleteAll();

        for i := 0 to JArray.Count() - 1 do begin
            if not JArray.Get(i, JToken) then
                Error(
                    'Unable to read Todo record at array index %1.',
                    i);

            if not JToken.IsObject() then
                Error(
                    'Todo record at array index %1 must be a JSON object.',
                    i);

            JObject := JToken.AsObject();
            AddTodoToTemporaryBuffer(
                JObject,
                i,
                TempExternalTodo);
        end;
    end;

    local procedure AddTodoToTemporaryBuffer(
        JObject: JsonObject;
        ArrayIndex: Integer;
        var TempExternalTodo: Record "APSS External Todo" temporary)
    var
        ExternalTodoId: Integer;
        ExternalUserId: Integer;
        Title: Text;
        Completed: Boolean;
    begin
        ExternalUserId :=
            GetRequiredPositiveInteger(
                JObject,
                'userId',
                ArrayIndex);

        ExternalTodoId :=
            GetRequiredPositiveInteger(
                JObject,
                'id',
                ArrayIndex);

        Title :=
            GetRequiredTitle(
                JObject,
                ArrayIndex,
                MaxStrLen(TempExternalTodo.Title));

        Completed :=
            GetRequiredBoolean(
                JObject,
                'completed',
                ArrayIndex);

        if TempExternalTodo.Get(ExternalTodoId) then
            Error(
                'Todo record at array index %1 has duplicate id %2.',
                ArrayIndex,
                ExternalTodoId);

        TempExternalTodo.Init();
        TempExternalTodo."External Todo ID" := ExternalTodoId;
        TempExternalTodo."External User ID" := ExternalUserId;
        TempExternalTodo.Title := Title;
        TempExternalTodo.Completed := Completed;
        TempExternalTodo.Insert();
    end;

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

        if not TryGetInteger(Value, IntegerValue) then
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

    [TryFunction]
    local procedure TryGetInteger(
        Value: JsonValue;
        var IntegerValue: Integer)
    begin
        IntegerValue := Value.AsInteger();
    end;

    local procedure GetRequiredTitle(
        JObject: JsonObject;
        ArrayIndex: Integer;
        MaximumLength: Integer): Text
    var
        ValueToken: JsonToken;
        Value: JsonValue;
        SerializedValue: Text;
        Title: Text;
    begin
        GetRequiredValueToken(
            JObject,
            'title',
            ArrayIndex,
            ValueToken);

        Value := ValueToken.AsValue();
        Value.WriteTo(SerializedValue);

        if (StrLen(SerializedValue) < 2) or
           (SerializedValue[1] <> '"') or
           (SerializedValue[StrLen(SerializedValue)] <> '"')
        then
            Error(
                'Todo record at array index %1 has a non-text title value.',
                ArrayIndex);

        Title := Value.AsText();

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

    local procedure GetRequiredBoolean(
        JObject: JsonObject;
        PropertyName: Text;
        ArrayIndex: Integer): Boolean
    var
        ValueToken: JsonToken;
        Value: JsonValue;
        SerializedValue: Text;
    begin
        GetRequiredValueToken(
            JObject,
            PropertyName,
            ArrayIndex,
            ValueToken);

        Value := ValueToken.AsValue();
        Value.WriteTo(SerializedValue);

        case SerializedValue of
            'true':
                exit(true);
            'false':
                exit(false);
        end;

        Error(
            'Todo record at array index %1 has a non-Boolean %2 value.',
            ArrayIndex,
            PropertyName);
    end;

    local procedure GetRequiredValueToken(
        JObject: JsonObject;
        PropertyName: Text;
        ArrayIndex: Integer;
        var ValueToken: JsonToken)
    begin
        if not JObject.Get(PropertyName, ValueToken) then
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