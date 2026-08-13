codeunit 50101 "APSS Json Array Parser"
{
    trigger OnRun()
    begin
    end;

    procedure ParseJsonArrayExample(JsonArrayText: Text)
    var
        JArray: JsonArray;
        JToken: JsonToken;
        JObject: JsonObject;
        TitleToken: JsonToken;
        i: Integer;
    begin
        if JArray.ReadFrom(JsonArrayText) then begin
            for i := 0 to JArray.Count() - 1 do begin
                if JArray.Get(i, JToken) then begin
                    if JToken.IsObject() then begin
                        JObject := JToken.AsObject();
                        if JObject.Get('title', TitleToken) then begin
                            Message('Array Item %1 Title: %2', i, TitleToken.AsValue().AsText());
                        end;
                    end;
                end;
            end;
        end else begin
            Error('Invalid JSON Array format.');
        end;
    end;
}
