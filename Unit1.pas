unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, XPMan, PerlRegEx, pcre;

type
   TPVariables = record
      variable : String;
      NumberOfUses : Integer;
      P : Boolean;
      M : Boolean;
      C : Boolean;
      T : Boolean;
   end;
   TPVariablesArray = array of TPVariables;
  TForm1 = class(TForm)
    btn1: TButton;
    mmo2: TMemo;
    btn2: TButton;
    mmo1: TMemo;
    dlgOpen1: TOpenDialog;
    XPManifest1: TXPManifest;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure SearchGlobalVars(var stringForSearch : String; var variables : TPVariablesArray);
    procedure SearchControlVars(var stringForSearch : String; var variables : TPVariablesArray);
    procedure SearchEnterVars(var stringForSearch : String; var variables : TPVariablesArray);
    procedure SearchModifiedVars(var stringForSearch : String; var variables : TPVariablesArray);
    procedure SearchSpuriousVars(var stringForSearch : String; var variables : TPVariablesArray);
    procedure DeleteCommentary(var stringForDelete : String);
    procedure DeleteStrings(var stringForDelete : String);
  end;

var
  Form1: TForm1;
  sFile: Text;
  sFileName : String;
  allVariables : TPVariablesArray;

implementation

{$R *.dfm}

procedure TForm1.btn1Click(Sender: TObject);
var
   TextFromFile, ToMemo : String;
begin
   if (DlgOpen1.Execute) then
      begin
         ToMemo := '';
         TextFromFile := '';
         mmo1.Clear;
         sFileName := DlgOpen1.FileName;
         AssignFile(sFile, sFileName);
         Reset(sFile);
         while (not(Eof(sFile))) do
            begin
               Readln(sFile,TextFromFile);
               ToMemo := ToMemo + TextFromFile + #13#10;
            end;
         CloseFile(sFile);
         mmo1.Text := ToMemo;
      end;
end;

procedure TForm1.btn2Click(Sender: TObject);
var
   i : Integer;
   RegEx : TPerlRegEx;
   StringForCode : String;
   CountP, CountM, CountC, CountT : Integer;
   ResultQ : Double;
begin
   StringForCode := mmo1.Text;
   StringForCode := UpperCase(StringForCode);
   for i:=0 to Length(allVariables) - 1 do
   begin
      allVariables[i].NumberOfUses := 0;
      allVariables[i].P := False;
      allVariables[i].C := False;
      allVariables[i].M := False;
      allVariables[i].T := False;
   end;
   DeleteStrings(StringForCode);
   DeleteCommentary(StringForCode);
   SearchGlobalVars(StringForCode, allVariables);
   SearchControlVars(StringForCode, allVariables);
   SearchEnterVars(StringForCode, allVariables);
   SearchModifiedVars(StringForCode, allVariables);
   SearchSpuriousVars(StringForCode, allVariables);
   mmo2.Clear;
   for i:=0 to Length(allVariables) - 1 do
   begin
      mmo2.Text := mmo2.Text + allVariables[i].variable + #13#10 + 'P : ' + BoolToStr(allVariables[i].P) + ' M : ' + BoolToStr(allVariables[i].M) + ' C : ' + BoolToStr(allVariables[i].C) + ' T : ' + BoolToStr(allVariables[i].T) + #13#10;
      if (allvariables[i].P = True) then
         inc(CountP);
      if (allVariables[i].M = True) then
         inc(CountM);
      if (allVariables[i].C = True) then
         inc(CountC);
      if (allVariables[i].T = True) then
         inc(CountT);
   end;
   ResultQ := 1 * CountP + 2 * CountM + 3 * CountC + 0.5 * CountT;
   mmo2.Text := mmo2.Text + #13#10 + 'Кол-во P: ' + IntToStr(CountP) + #13#10 + 'Кол-во M: ' + IntToStr(CountM) + #13#10
   + 'Кол-во C: ' + IntToStr(CountC) + #13#10 + 'Кол-во T: ' + IntToStr(CountT) + #13#10 + 'Результат Q = '
   + FloatToStrF(ResultQ, ffGeneral, 1, 2);
end;

procedure TForm1.DeleteCommentary(var stringForDelete : String);
var
   i : Integer;
   RegEx : TPerlRegEx;
begin
   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '[\s\d]+\*.*?.*';
   RegEx.Subject := stringForDelete;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         Delete(stringForDelete, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForDelete;
      until not(RegEx.MatchAgain);
   end;
   RegEx.RegEx := '\*\>.*';
   RegEx.Subject := stringForDelete;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         Delete(stringForDelete, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForDelete;
      until not(RegEx.MatchAgain);
   end;
   RegEx.RegEx := '\/.*';
   RegEx.Subject := stringForDelete;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         Delete(stringForDelete, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForDelete;
      until not(RegEx.MatchAgain);
   end;
   //mmo1.Text := stringForDelete;
end;

procedure TForm1.DeleteStrings(var stringForDelete: String);
var
   RegEx : TPerlRegEx;
begin
   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '[\''\"].*[\''\"]';
   RegEx.Subject := stringForDelete;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         Delete(stringForDelete, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForDelete;
      until not(RegEx.MatchAgain);
   end;
   //mmo1.Text := stringForDelete;
end;

procedure TForm1.SearchControlVars(var stringForSearch: String; var variables: TPVariablesArray);
var
   i : Integer;
   RegEx, RegExTwo : TPerlRegEx;
   NewReg, DeleteOtherSymb : String;
   DeleteThisVar : Boolean;
begin
   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '(?<=IF\s|OR\s)\s*[A-Z][A-Z\d\-]*';
   RegEx.Subject := stringForSearch;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll, rfIgnoreCase]);
         DeleteThisVar := False;
         for i:=0 to Length(variables) - 1 do
            if (DeleteOtherSymb = variables[i].variable) then
            begin
               variables[i].C := True;
               DeleteThisVar := True;
            end;
         if (DeleteThisVar) then
         begin
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
         end;
      until not (RegEx.MatchAgain);
   end;
   RegEx.RegEx := '(?<=PERFORM\sVARYING\s|UNTIL\s|WITH\sTEST\sAFTER\sUNTIL\s|BEFORE\sUNTIL\s)\s*[A-Z][A-Z\d\-]*';
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll, rfIgnoreCase]);
         DeleteThisVar := False;
         for i:=0 to Length(variables) - 1 do
            if (DeleteOtherSymb = variables[i].variable) then
            begin
               variables[i].C := True;
               DeleteThisVar := True;
            end;
         if (DeleteThisVar) then
         begin
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
         end;
      until not(RegEx.MatchAgain);
   end;
   RegEx.RegEx := '(?<=EVALUATE\s)\s*[A-Z][A-Z\-\d]*';
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll, rfIgnoreCase]);
         DeleteThisVar := False;
         for i:=0 to Length(variables) - 1 do
         begin
            if (DeleteOtherSymb = variables[i].variable) then
            begin
               variables[i].C := True;
               DeleteThisVar := True;
            end;
         end;
         if (DeleteThisVar) then
         begin
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
         end;
      until not(RegEx.MatchAgain);
   end;
   RegEx.RegEx := '(?<=WHEN\s)\s*[A-Z][A-Z\d\-]+';
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll, rfIgnoreCase]);
         DeleteThisVar := False;
         for i:=0 to Length(variables) - 1 do
         begin
            if (DeleteOtherSymb = variables[i].variable) then
            begin
               variables[i].C := True;
               if (variables[i].M = False) then
                  variables[i].P := True;
               DeleteThisVar := True;
            end;
         end;
         if (DeleteThisVar) then
         begin
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
         end;
      until not(RegEx.MatchAgain);
   end;
   //mmo1.Text := stringForSearch;
end;

procedure TForm1.SearchEnterVars(var stringForSearch: String; var variables: TPVariablesArray);
var
   i : Integer;
   RegEx, RegExTwo : TPerlRegEx;
   DeleteThisVar : Boolean;
   NewReg, DeleteOtherSymb : String;
begin
   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '(?<=ACCEPT\s)\s*[A-Z][A-Z\d\-]*';
   RegEx.Subject := stringForSearch;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll, rfIgnoreCase]);
         DeleteThisVar := False;
         for i:=0 to Length(variables) - 1 do
            if (DeleteOtherSymb = variables[i].variable) then
               if (variables[i].M = False) then
               begin
                  variables[i].P := True;
                  DeleteThisVar := True;
               end;
         if (DeleteThisVar) then
         begin
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
         end;
      until not(RegEx.MatchAgain);
   end;

   RegEx := TPerlRegEx.Create;
   RegExTwo := TPerlRegEx.Create;
   RegExTwo.RegEx := '[A-Z][A-Z\d\-]*';
   RegEx.Subject := stringForSearch;
   RegEx.RegEx := '(?<=ADD\s)\s*[A-Z][A-Z\d\- ]*(?=\sTO)';
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         NewReg := RegEx.MatchedText;
         RegExTwo.Subject := NewReg;
         if (RegExTwo.Match) then
         begin
            repeat
               DeleteThisVar := False;
               for i:=0 to Length(variables) - 1 do
                  if (RegExTwo.MatchedText = variables[i].variable) then
                  begin
                     if (variables[i].M = False) then
                        variables[i].P := True;
                     DeleteThisVar := True;
                  end;
               if (DeleteThisVar) then
               begin
                  Delete(NewReg, RegExTwo.MatchedOffset, RegExTwo.MatchedLength);
                  RegExTwo.Subject := NewReg;
               end;
            until not(RegExTwo.MatchAgain);
         end;
         Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForSearch;
      until not(RegEx.MatchAgain);
   end;
   RegEx.RegEx := '(?<=DIVIDE\s|MULTIPLY\s|SUBTRACT\s)[A-Z][A-Z\-\d]*';
   RegEx.Subject := stringForSearch;
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll, rfIgnoreCase]);
         DeleteThisVar := False;
         for i:=0 to Length(variables) - 1 do
            if (DeleteOtherSymb = variables[i].variable) then
            begin
               if (variables[i].M = False) then
                  variables[i].P := True;
               DeleteThisVar := True;
            end;
         if (DeleteThisVar) then
         begin
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
         end;
      until not(RegEx.MatchAgain);
   end;
   RegEx.RegEx := '(?<=DISPLAY\s)[\s\,]*[A-Z][A-Z\-\d]+';
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         NewReg := RegEx.MatchedText;
         NewReg := StringReplace(NewReg, ' ','',[rfReplaceAll,rfIgnoreCase]);
         for i:=0 to Length(variables) - 1 do
            if (NewReg = variables[i].variable) then
               if (variables[i].M = False) then
                  variables[i].P := True;
         Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForSearch;
      until not(RegEx.MatchAgain);
   end;
   //mmo1.Text := stringForSearch;
end;

procedure TForm1.SearchGlobalVars(var stringForSearch: String;
  var variables: TPVariablesArray);
var
   RegEx : TPerlRegEx;
   i, CountVariables: Integer;
   VarFind : Boolean;
   DeleteOtherSymb : String;
begin
   i := 0;
   CountVariables := 0;
   RegEx := TPerlRegEx.Create;
   RegEx.RegEx := '(?<=\s)[A-Z]+[A-Z\-\d]*(?=\s+PIC\s[A-Z\d\(\)]+\sVALUES)';
   RegEx.Subject := stringForSearch;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         VarFind := False;
         for i:=0 to Length(variables) - 1 do
            if (RegEx.MatchedText = variables[i].variable) then
               VarFind := True;
         if (VarFind = False) then
         begin
            SetLength(variables, CountVariables + 1);
            variables[CountVariables].variable := RegEx.MatchedText;
            variables[CountVariables].NumberOfUses := 0;
            variables[CountVariables].P := True;
            variables[CountVariables].M := False;
            variables[CountVariables].C := False;
            variables[CountVariables].T := False;
            inc(CountVariables);
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
         end;
      until not(RegEx.MatchAgain);
   end;

   RegEx.RegEx := '(?<=\s)[A-Z]+[A-Z\-\d]*(?=\s+PIC\s)';
   RegEx.Subject := stringForSearch;
   if (RegEx.Match) then
   begin
      repeat
         VarFind := False;
         for i:=0 to Length(variables) - 1 do
            if (RegEx.MatchedText = variables[i].variable) then
               VarFind := True;
         if (VarFind = False) then
         begin
            SetLength(variables, CountVariables + 1);
            variables[CountVariables].variable := RegEx.MatchedText;
            variables[CountVariables].NumberOfUses := 0;
            variables[CountVariables].P := False;
            variables[CountVariables].C := False;
            variables[CountVariables].M := False;
            variables[CountVariables].T := False;
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
            inc(CountVariables);
         end;
      until not (RegEx.MatchAgain);
   end;

   RegEx.RegEx := '(?<=\s\d\d\s)\s*[A-Z]+[\-\dA-Z]+';
   RegEx.Subject := stringForSearch;
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll, rfIgnoreCase]);
         VarFind := False;
         for i:=0 to Length(variables) - 1 do
            if (DeleteOtherSymb = variables[i].variable) or (DeleteOtherSymb = 'PIC') or (DeleteOtherSymb = 'MOVE') or
            (DeleteOtherSymb = #13#10 + 'SUBTRACT') OR (DeleteOtherSymb = 'TIMES') or (DeleteOtherSymb = 'OR') or
            (DeleteOtherSymb = 'OCCURS') OR (DeleteOtherSymb = 'USAGE') OR (DeleteOtherSymb = 'VALUE') then
               VarFind := True;
         if (VarFind = False) then
         begin
            SetLength(variables, CountVariables + 1);
            variables[CountVariables].variable := DeleteOtherSymb;
            variables[CountVariables].NumberOfUses := 0;
            variables[CountVariables].P := False;
            variables[CountVariables].C := False;
            variables[CountVariables].M := False;
            variables[CountVariables].T := False;
            Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
            RegEx.Subject := stringForSearch;
            inc(CountVariables);
         end;
      until not (RegEx.MatchAgain);
   end;
   //mmo1.Text := stringForSearch;
   for i:=0 to Length(variables) - 1 do
      mmo2.Text := mmo2.Text + variables[i].variable + #13#10;
end;

procedure TForm1.SearchModifiedVars(var stringForSearch: String; var variables: TPVariablesArray);
var
   i : Integer;
   RegEx, RegExTwo : TPerlRegEx;
   NewReg : String;
   DeleteThisVar : Boolean;
   DeleteOtherSymb : String;
begin
   RegEx := TPerlRegEx.Create;
   RegExTwo := TPerlRegEx.Create;
   RegExTwo.RegEx := '[A-Z][A-Z\-\d]*';
   RegEx.RegEx := '(?<=MOVE\s).*';
   RegEx.Subject := stringForSearch;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         RegExTwo.Subject := RegEx.MatchedText;
         if (RegExTwo.Match) then
         begin
            repeat
               for i:=0 to Length(variables) - 1 do
                  if (RegExTwo.MatchedText = variables[i].variable) then
                  begin
                     if (variables[i].P = True) then
                        variables[i].P := False;
                     variables[i].M := True;
                  end;
            until not(RegExTwo.MatchAgain);
         end;
         Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForSearch;
      until not(RegEx.MatchAgain);
   end;
   RegEx.RegEx := '(?<=TO\s|GIVING\s|REMAINDER\s|FROM\s)[A-Z][A-Z\-\d]*';
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll, rfIgnoreCase]);
         for i:=0 to Length(variables) - 1 do
            if (DeleteOtherSymb = variables[i].variable) then
            begin
               if (variables[i].P = True) then
                  variables[i].P := False;
               variables[i].M := True;
            end;
         Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForSearch;
      until not(RegEx.MatchAgain);
   end;
   RegEx.RegEx := '(?<=SET)\s*[A-Z][A-Z\d\-]*';
   RegEx.Subject := stringForSearch;
   RegEx.Compile;
   if (RegEx.Match) then
   begin
      repeat
         DeleteOtherSymb := RegEx.MatchedText;
         DeleteOtherSymb := StringReplace(DeleteOtherSymb,' ','',[rfReplaceAll,rfIgnoreCase]);
         for i:=0 to Length(variables) - 1 do
            if (DeleteOtherSymb = variables[i].variable) then
            begin
               if (variables[i].P = True) then
                  variables[i].P := False;
               variables[i].M := True;
            end;
         Delete(stringForSearch, RegEx.MatchedOffset, RegEx.MatchedLength);
         RegEx.Subject := stringForSearch;
      until not(RegEx.MatchAgain);
   end;
   //mmo1.Text := stringForSearch;
end;

procedure TForm1.SearchSpuriousVars(var stringForSearch: String; var variables: TPVariablesArray);
var
   i : Integer;
begin
   for i:=0 to Length(variables) - 1 do
      if (variables[i].P = False) and (variables[i].M = False) and (variables[i].C = False) then
         variables[i].T := True;
end;

end.
