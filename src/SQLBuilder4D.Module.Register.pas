(*
  Copyright 2013 Ezequiel Juliano Müller - ezequieljuliano@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*)

unit SQLBuilder4D.Module.Register;

interface

implementation

uses
  Spring,
  Spring.Container,
  SQLBuilder4D,
  SQLBuilder4D.Impl;

procedure RegisterClasses();
begin
  GlobalContainer.RegisterType<TSQLTable>.Implements<ISQLTable>.AsTransient;
  GlobalContainer.RegisterType<TSQLValue>.Implements<ISQLValue>.AsTransient;
  GlobalContainer.RegisterType<TSQLJoin>.Implements<ISQLJoin>.AsTransient;
  GlobalContainer.RegisterType<TSQLUnion>.Implements<ISQLUnion>.AsTransient;
  GlobalContainer.RegisterType<TSQLCriteria>.Implements<ISQLCriteria>.AsTransient;
  GlobalContainer.RegisterType<TSQLOrderBy>.Implements<ISQLOrderBy>.AsTransient;
  GlobalContainer.RegisterType<TSQLHaving>.Implements<ISQLHaving>.AsTransient;
  GlobalContainer.RegisterType<TSQLGroupBy>.Implements<ISQLGroupBy>.AsTransient;
  GlobalContainer.RegisterType<TSQLWhere>.Implements<ISQLWhere>.AsTransient;

  GlobalContainer.RegisterType<TSQLUpdate>.Implements<ISQLUpdate>.AsTransient;
  GlobalContainer.RegisterType<TSQLDelete>.Implements<ISQLDelete>.AsTransient;
  GlobalContainer.RegisterType<TSQLInsert>.Implements<ISQLInsert>.AsTransient;
  GlobalContainer.RegisterType<TSQLSelect>.Implements<ISQLSelect>.AsTransient;

  GlobalContainer.Build;
end;

initialization

RegisterClasses();

end.
