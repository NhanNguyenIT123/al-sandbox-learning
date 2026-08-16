codeunit 50101 "APSS Json Array Parser"
{
    trigger OnRun()
    begin
    end;

    procedure ParseJsonArrayExample(JsonArrayText: Text)
    var
        JArray: JsonArray;
        Index: Integer;
        Output: TextBuilder;
    begin
        if not JArray.ReadFrom(JsonArrayText) then
            Error(InvalidJsonArrayErr);

        for Index := 0 to JArray.Count() - 1 do
            Output.AppendLine(GetArrayItemText(JArray, Index));

        Message(ArrayItemsMsg, Output.ToText());
    end;

    local procedure GetArrayItemText(JsonArray: JsonArray; Index: Integer): Text
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        TitleToken: JsonToken;
    begin
        if not JsonArray.Get(Index, JsonToken) then
            Error(ArrayItemErr, Index);
        if not JsonToken.IsObject() then
            Error(ArrayItemTypeErr, Index);

        JsonObject := JsonToken.AsObject();
        if not JsonObject.Get('title', TitleToken) then
            Error(MissingTitleErr, Index);
        if not TitleToken.IsValue() then
            Error(InvalidTitleErr, Index);

        exit(StrSubstNo(ArrayItemMsg, Index, TitleToken.AsValue().AsText()));
    end;

    var
        ArrayItemErr: Label 'Could not read the item at array index %1.', Comment = '%1 = zero-based JSON array index';
        ArrayItemMsg: Label 'Array item %1 title: %2', Comment = '%1 = zero-based JSON array index, %2 = title value';
        ArrayItemsMsg: Label 'Array items:\%1', Comment = '%1 = formatted array item list';
        ArrayItemTypeErr: Label 'The item at array index %1 is not a JSON object.', Comment = '%1 = zero-based JSON array index';
        InvalidJsonArrayErr: Label 'Invalid JSON array format.';
        InvalidTitleErr: Label 'The title on the item at array index %1 is not a JSON value.', Comment = '%1 = zero-based JSON array index';
        MissingTitleErr: Label 'The item at array index %1 does not contain a title.', Comment = '%1 = zero-based JSON array index';
}
