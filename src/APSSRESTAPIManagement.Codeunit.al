codeunit 50100 "APSS REST API Management"
{
    Permissions = tabledata "APSS External User" = RIMD;

    trigger OnRun()
    begin
    end;

    procedure FetchExternalData()
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        ResponseString: Text;
        JObject: JsonObject;
        JToken: JsonToken;
        Title: Text;
    begin
        if not Client.Get(TodoEndpointLbl, ResponseMessage) then
            Error(HttpRequestFailedErr, TodoEndpointLbl);
        if not ResponseMessage.IsSuccessStatusCode() then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), TodoEndpointLbl);

        ResponseMessage.Content().ReadAs(ResponseString);
        if not JObject.ReadFrom(ResponseString) then
            Error(InvalidObjectJsonErr, TodoEndpointLbl);
        if not JObject.Get('title', JToken) then
            Error(MissingResponsePropertyErr, 'title', TodoEndpointLbl);
        if not JToken.IsValue() then
            Error(InvalidResponsePropertyErr, 'title', TodoEndpointLbl);

        Title := JToken.AsValue().AsText();
        Message(FetchSucceededMsg, Title);
    end;

    procedure SendDataToExternalApi(CustomerNo: Code[20]; CustomerName: Text[100])
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        ResponseString: Text;
        JObject: JsonObject;
        PayloadText: Text;
    begin
        JObject.Add('title', StrSubstNo(CustomerTitleLbl, CustomerNo, CustomerName));
        JObject.Add('body', PostBodyLbl);
        JObject.Add('userId', 1);

        JObject.WriteTo(PayloadText);
        Content.WriteFrom(PayloadText);

        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add(ContentTypeHeaderLbl, JsonContentTypeLbl);

        if not Client.Post(PostsEndpointLbl, Content, ResponseMessage) then
            Error(HttpPostFailedErr, PostsEndpointLbl);
        if not ResponseMessage.IsSuccessStatusCode() then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), PostsEndpointLbl);

        ResponseMessage.Content().ReadAs(ResponseString);
        Message(PostSucceededMsg, ResponseString);
    end;

    procedure SyncExternalUsers(var InsertedCount: Integer; var ModifiedCount: Integer; var DeletedCount: Integer)
    var
        TempExternalUser: Record "APSS External User" temporary;
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        SyncDateTime: DateTime;
    begin
        Clear(InsertedCount);
        Clear(ModifiedCount);
        Clear(DeletedCount);

        if not Client.Get(UsersEndpointLbl, ResponseMessage) then
            Error(HttpRequestFailedErr, UsersEndpointLbl);

        if not ResponseMessage.IsSuccessStatusCode() then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), UsersEndpointLbl);

        ResponseMessage.Content().ReadAs(ResponseText);
        ParseExternalUsers(ResponseText, TempExternalUser);

        SyncDateTime := CurrentDateTime();
        UpsertExternalUsers(TempExternalUser, SyncDateTime, InsertedCount, ModifiedCount);
        DeleteMissingExternalUsers(TempExternalUser, DeletedCount);
    end;

    procedure ClearExternalUsers(): Integer
    var
        ExternalUser: Record "APSS External User";
        DeletedCount: Integer;
    begin
        DeletedCount := ExternalUser.Count();
        if DeletedCount = 0 then
            exit(0);

        ExternalUser.DeleteAll(true);
        exit(DeletedCount);
    end;

    local procedure ParseExternalUsers(ResponseText: Text; var TempExternalUser: Record "APSS External User" temporary)
    var
        UserArray: JsonArray;
        UserObject: JsonObject;
        UserToken: JsonToken;
        Index: Integer;
    begin
        TempExternalUser.Reset();
        TempExternalUser.DeleteAll();

        if not UserArray.ReadFrom(ResponseText) then
            Error(InvalidJsonErr);

        if UserArray.Count() = 0 then
            Error(EmptyResponseErr);

        for Index := 0 to UserArray.Count() - 1 do begin
            if not UserArray.Get(Index, UserToken) then
                Error(ArrayItemErr, Index);
            if not UserToken.IsObject() then
                Error(ArrayItemTypeErr, Index);

            UserObject := UserToken.AsObject();
            ParseExternalUser(UserObject, TempExternalUser, Index);
            if not TempExternalUser.Insert() then
                Error(DuplicateIdErr, TempExternalUser."External ID");
        end;
    end;

    local procedure ParseExternalUser(UserObject: JsonObject; var TempExternalUser: Record "APSS External User" temporary; Index: Integer)
    var
        AddressObject: JsonObject;
        CompanyObject: JsonObject;
        GeoObject: JsonObject;
    begin
        TempExternalUser.Init();
        TempExternalUser."External ID" := GetRequiredInteger(UserObject, 'id', Index);
        TempExternalUser.Name := CopyStr(GetRequiredText(UserObject, 'name', MaxStrLen(TempExternalUser.Name), Index), 1, MaxStrLen(TempExternalUser.Name));
        TempExternalUser."User Name" := CopyStr(GetOptionalText(UserObject, 'username', MaxStrLen(TempExternalUser."User Name"), Index), 1, MaxStrLen(TempExternalUser."User Name"));
        TempExternalUser."E-mail" := CopyStr(GetRequiredText(UserObject, 'email', MaxStrLen(TempExternalUser."E-mail"), Index), 1, MaxStrLen(TempExternalUser."E-mail"));
        TempExternalUser.Phone := CopyStr(GetOptionalText(UserObject, 'phone', MaxStrLen(TempExternalUser.Phone), Index), 1, MaxStrLen(TempExternalUser.Phone));
        TempExternalUser.Website := CopyStr(GetOptionalText(UserObject, 'website', MaxStrLen(TempExternalUser.Website), Index), 1, MaxStrLen(TempExternalUser.Website));

        if TryGetObject(UserObject, 'company', CompanyObject) then
            TempExternalUser."Company Name" := CopyStr(GetOptionalText(CompanyObject, 'name', MaxStrLen(TempExternalUser."Company Name"), Index), 1, MaxStrLen(TempExternalUser."Company Name"));

        if TryGetObject(UserObject, 'address', AddressObject) then begin
            TempExternalUser.Street := CopyStr(GetOptionalText(AddressObject, 'street', MaxStrLen(TempExternalUser.Street), Index), 1, MaxStrLen(TempExternalUser.Street));
            TempExternalUser.Suite := CopyStr(GetOptionalText(AddressObject, 'suite', MaxStrLen(TempExternalUser.Suite), Index), 1, MaxStrLen(TempExternalUser.Suite));
            TempExternalUser.City := CopyStr(GetOptionalText(AddressObject, 'city', MaxStrLen(TempExternalUser.City), Index), 1, MaxStrLen(TempExternalUser.City));
            TempExternalUser."Post Code" := CopyStr(GetOptionalText(AddressObject, 'zipcode', MaxStrLen(TempExternalUser."Post Code"), Index), 1, MaxStrLen(TempExternalUser."Post Code"));
            if TryGetObject(AddressObject, 'geo', GeoObject) then begin
                TempExternalUser.Latitude := GetOptionalDecimal(GeoObject, 'lat', Index);
                TempExternalUser.Longitude := GetOptionalDecimal(GeoObject, 'lng', Index);
            end;
        end;
    end;

    local procedure UpsertExternalUsers(var TempExternalUser: Record "APSS External User" temporary; SyncDateTime: DateTime; var InsertedCount: Integer; var ModifiedCount: Integer)
    var
        ExternalUser: Record "APSS External User";
        RecordChanged: Boolean;
    begin
        if not TempExternalUser.FindSet() then
            exit;

        repeat
            if ExternalUser.Get(TempExternalUser."External ID") then begin
                RecordChanged := ExternalUserChanged(ExternalUser, TempExternalUser);
                CopyExternalUser(TempExternalUser, ExternalUser, SyncDateTime);
                ExternalUser.Modify(true);
                if RecordChanged then
                    ModifiedCount += 1;
            end else begin
                ExternalUser.Init();
                CopyExternalUser(TempExternalUser, ExternalUser, SyncDateTime);
                ExternalUser.Insert(true);
                InsertedCount += 1;
            end;
        until TempExternalUser.Next() = 0;
    end;

    local procedure DeleteMissingExternalUsers(var TempExternalUser: Record "APSS External User" temporary; var DeletedCount: Integer)
    var
        ExternalUser: Record "APSS External User";
    begin
        if not ExternalUser.FindSet(true) then
            exit;

        repeat
            if not TempExternalUser.Get(ExternalUser."External ID") then begin
                ExternalUser.Delete(true);
                DeletedCount += 1;
            end;
        until ExternalUser.Next() = 0;
    end;

    local procedure CopyExternalUser(TempExternalUser: Record "APSS External User" temporary; var ExternalUser: Record "APSS External User"; SyncDateTime: DateTime)
    begin
        ExternalUser."External ID" := TempExternalUser."External ID";
        ExternalUser.Name := TempExternalUser.Name;
        ExternalUser."User Name" := TempExternalUser."User Name";
        ExternalUser."E-mail" := TempExternalUser."E-mail";
        ExternalUser.Phone := TempExternalUser.Phone;
        ExternalUser.Website := TempExternalUser.Website;
        ExternalUser."Company Name" := TempExternalUser."Company Name";
        ExternalUser.Street := TempExternalUser.Street;
        ExternalUser.Suite := TempExternalUser.Suite;
        ExternalUser.City := TempExternalUser.City;
        ExternalUser."Post Code" := TempExternalUser."Post Code";
        ExternalUser.Latitude := TempExternalUser.Latitude;
        ExternalUser.Longitude := TempExternalUser.Longitude;
        ExternalUser."Last Synced At" := SyncDateTime;
    end;

    local procedure ExternalUserChanged(ExternalUser: Record "APSS External User"; TempExternalUser: Record "APSS External User" temporary): Boolean
    begin
        exit(
            (ExternalUser.Name <> TempExternalUser.Name) or
            (ExternalUser."User Name" <> TempExternalUser."User Name") or
            (ExternalUser."E-mail" <> TempExternalUser."E-mail") or
            (ExternalUser.Phone <> TempExternalUser.Phone) or
            (ExternalUser.Website <> TempExternalUser.Website) or
            (ExternalUser."Company Name" <> TempExternalUser."Company Name") or
            (ExternalUser.Street <> TempExternalUser.Street) or
            (ExternalUser.Suite <> TempExternalUser.Suite) or
            (ExternalUser.City <> TempExternalUser.City) or
            (ExternalUser."Post Code" <> TempExternalUser."Post Code") or
            (ExternalUser.Latitude <> TempExternalUser.Latitude) or
            (ExternalUser.Longitude <> TempExternalUser.Longitude));
    end;

    local procedure GetRequiredInteger(JsonObject: JsonObject; PropertyName: Text; ItemIndex: Integer): Integer
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        IntegerValue: Integer;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            Error(MissingPropertyErr, PropertyName, ItemIndex);
        if not JsonToken.IsValue() then
            Error(InvalidPropertyErr, PropertyName, ItemIndex);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() then
            Error(MissingPropertyErr, PropertyName, ItemIndex);
        if not Evaluate(IntegerValue, JsonValue.AsText(), 9) then
            Error(InvalidPropertyErr, PropertyName, ItemIndex);

        exit(IntegerValue);
    end;

    local procedure GetRequiredText(JsonObject: JsonObject; PropertyName: Text; MaximumLength: Integer; ItemIndex: Integer): Text
    var
        PropertyValue: Text;
    begin
        PropertyValue := GetOptionalText(JsonObject, PropertyName, MaximumLength, ItemIndex);
        if PropertyValue = '' then
            Error(MissingPropertyErr, PropertyName, ItemIndex);

        exit(PropertyValue);
    end;

    local procedure GetOptionalText(JsonObject: JsonObject; PropertyName: Text; MaximumLength: Integer; ItemIndex: Integer): Text
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        PropertyValue: Text;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            exit('');
        if not JsonToken.IsValue() then
            Error(InvalidPropertyErr, PropertyName, ItemIndex);

        JsonValue := JsonToken.AsValue();
        if JsonValue.IsNull() then
            exit('');

        PropertyValue := JsonValue.AsText();
        if StrLen(PropertyValue) > MaximumLength then
            Error(PropertyTooLongErr, PropertyName, ItemIndex, StrLen(PropertyValue), MaximumLength);

        exit(PropertyValue);
    end;

    local procedure GetOptionalDecimal(JsonObject: JsonObject; PropertyName: Text; ItemIndex: Integer): Decimal
    var
        DecimalValue: Decimal;
        PropertyText: Text;
    begin
        PropertyText := GetOptionalText(JsonObject, PropertyName, 50, ItemIndex);
        if PropertyText = '' then
            exit(0);
        if not Evaluate(DecimalValue, PropertyText, 9) then
            Error(InvalidPropertyErr, PropertyName, ItemIndex);

        exit(DecimalValue);
    end;

    local procedure TryGetObject(JsonObject: JsonObject; PropertyName: Text; var NestedObject: JsonObject): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, JsonToken) then
            exit(false);
        if not JsonToken.IsObject() then
            exit(false);

        NestedObject := JsonToken.AsObject();
        exit(true);
    end;

    var
        ArrayItemErr: Label 'Could not read external user at array index %1.', Comment = '%1 = zero-based JSON array index';
        ArrayItemTypeErr: Label 'The external user at array index %1 is not a JSON object.', Comment = '%1 = zero-based JSON array index';
        DuplicateIdErr: Label 'The external API returned duplicate user ID %1.', Comment = '%1 = external user ID';
        EmptyResponseErr: Label 'The external API returned an empty user list. Existing data was not changed.';
        ContentTypeHeaderLbl: Label 'Content-Type', Locked = true;
        CustomerTitleLbl: Label 'Customer %1: %2', Comment = '%1 = customer number, %2 = customer name';
        FetchSucceededMsg: Label 'Success! Fetched title: %1', Comment = '%1 = title returned by the external API';
        HttpPostFailedErr: Label 'The HTTP POST request to %1 failed. Verify the endpoint, network connection, and the extension HTTP client permission.', Comment = '%1 = API endpoint URL';
        HttpRequestFailedErr: Label 'The HTTP GET request to %1 failed. Verify the endpoint, network connection, and the extension HTTP client permission.', Comment = '%1 = API endpoint URL';
        HttpStatusErr: Label 'The external API returned HTTP status %1 for %2. Existing data was not changed.', Comment = '%1 = HTTP status code, %2 = API endpoint URL';
        InvalidObjectJsonErr: Label 'The response from %1 is not a valid JSON object.', Comment = '%1 = API endpoint URL';
        InvalidJsonErr: Label 'The external API response is not a valid JSON array. Existing data was not changed.';
        InvalidPropertyErr: Label 'Property %1 on external user at array index %2 has an invalid value.', Comment = '%1 = JSON property name, %2 = zero-based JSON array index';
        InvalidResponsePropertyErr: Label 'Property %1 in the response from %2 is not a JSON value.', Comment = '%1 = JSON property name, %2 = API endpoint URL';
        JsonContentTypeLbl: Label 'application/json; charset=utf-8', Locked = true;
        MissingPropertyErr: Label 'Required property %1 is missing from external user at array index %2.', Comment = '%1 = JSON property name, %2 = zero-based JSON array index';
        MissingResponsePropertyErr: Label 'Property %1 is missing from the response from %2.', Comment = '%1 = JSON property name, %2 = API endpoint URL';
        PostBodyLbl: Label 'Test data sent from Business Central';
        PostsEndpointLbl: Label 'https://jsonplaceholder.typicode.com/posts', Locked = true;
        PostSucceededMsg: Label 'Success! POST response:\%1', Comment = '%1 = response body returned by the external API';
        PropertyTooLongErr: Label 'Property %1 on external user at array index %2 contains %3 characters; the maximum supported length is %4.', Comment = '%1 = JSON property name, %2 = zero-based JSON array index, %3 = actual length, %4 = maximum length';
        TodoEndpointLbl: Label 'https://jsonplaceholder.typicode.com/todos/1', Locked = true;
        UsersEndpointLbl: Label 'https://jsonplaceholder.typicode.com/users', Locked = true;
}
