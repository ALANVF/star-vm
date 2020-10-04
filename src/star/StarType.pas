unit StarType;

{$SCOPEDENUMS+}

interface

type
	TStarType = class;

{var
	allTypes: array of TStarType;
	maxTypeID;}

type
	TStarType = class abstract
	public
		type
			TTypeID = qword;
			TBaseTypeID = qword;
			TAttr = (generic, sealed, uncounted, strong);
			TAttrs = set of TAttr;

	end;

implementation

end.