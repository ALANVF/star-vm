unit ContainerUtils;

{$modeSwitch ADVANCEDRECORDS}

interface

type
	generic TPair<TKey, TVal> = record
	private
		type
			TSelf = specialize TPair<TKey, TVal>;

	public
		key: TKey;
		value: TVal;

		class function create(key_: TKey; value_: TVal): TSelf; static;
	end;

implementation

class function TPair.create(key_: TKey; value_: TVal): TSelf; static;
begin
	result.key := key_;
	result.value := value_;
end;

end.