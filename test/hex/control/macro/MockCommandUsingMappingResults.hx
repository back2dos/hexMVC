package hex.control.macro;

import hex.control.command.BasicCommand;

/**
 * ...
 * @author Francis Bourre
 */
class MockCommandUsingMappingResults extends BasicCommand
{
	@Inject
	public var value : String;
	
	public function new()
	{
		super();
	}
	
	override public function execute() : Void
	{
		
	}
}