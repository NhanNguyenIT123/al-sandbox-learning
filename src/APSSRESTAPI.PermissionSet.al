permissionset 50100 "APSS REST API"
{
    Assignable = true;
    Caption = 'APSS REST API';

    Permissions =
        tabledata "APSS External User" = RIMD,
        table "APSS External User" = X,
        page "APSS External Users" = X,
        codeunit "APSS REST API Management" = X;
}
