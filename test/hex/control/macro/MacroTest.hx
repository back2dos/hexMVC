package hex.control.macro;

import haxe.Timer;
import hex.control.async.AsyncCommand;
import hex.control.async.IAsyncCommand;
import hex.control.async.IAsyncCommandListener;
import hex.control.command.CommandMapping;
import hex.control.macro.IMacroExecutor;
import hex.control.macro.MacroExecutor;
import hex.error.NullPointerException;
import hex.event.BasicEvent;
import hex.event.IEvent;
import hex.control.command.ICommand;
import hex.control.command.ICommandMapping;
import hex.control.macro.Macro;
import hex.error.IllegalStateException;
import hex.error.VirtualMethodException;
import hex.log.Stringifier;
import hex.MockDependencyInjector;
import hex.module.IModule;
import hex.unittest.assertion.Assert;

/**
 * ...
 * @author Francis Bourre
 */
class MacroTest
{
	private var _macro 			: Macro;
	private var _macroExecutor 	: MockMacroExecutor;

    @setUp
    public function setUp() : Void
    {
        this._macro 					= new MockMacro();
		this._macroExecutor 			= new MockMacroExecutor();
		this._macro.macroExecutor 		= this._macroExecutor;
		MockCommand.executeCallCount 	= 0;
    }

    @tearDown
    public function tearDown() : Void
    {
        this._macro 		= null;
		this._macroExecutor = null;
    }
	
	@test( "Test atomic property" )
	public function testIsAtomic() : Void
	{
		Assert.assertTrue( this._macro.isAtomic, "'isAtomic' should return true" );

		this._macro.isAtomic = false;
		Assert.failTrue( this._macro.isAtomic, "'isAtomic' should return false" );

		this._macro.isAtomic = true;
		Assert.assertTrue( this._macro.isAtomic, "'isAtomic' should return true" );
	}
	
	@test( "Test parallel and sequence modes" )
	public function testParallelAndSequenceModes() : Void
	{
		Assert.assertTrue( this._macro.isInSequenceMode, "'isInSequenceMode' should return true" );
		Assert.failTrue( this._macro.isInParallelMode, "'isInParallelMode' should return false" );

		this._macro.isInSequenceMode = false;
		Assert.failTrue( this._macro.isInSequenceMode, "'isInSequenceMode' should return false" );
		Assert.assertTrue( this._macro.isInParallelMode, "'isInParallelMode' should return true" );
		this._macro.isInSequenceMode = true;
		Assert.assertTrue( this._macro.isInSequenceMode, "'isInSequenceMode' should return true" );
		Assert.failTrue( this._macro.isInParallelMode, "'isInParallelMode' should return false" );

		this._macro.isInParallelMode = true;
		Assert.failTrue( _macro.isInSequenceMode, "'isInSequenceMode' should return false" );
		Assert.assertTrue( _macro.isInParallelMode, "'isInParallelMode' should return true" );
		this._macro.isInParallelMode = false;
		Assert.assertTrue( this._macro.isInSequenceMode, "'isInSequenceMode' should return true" );
		Assert.failTrue( this._macro.isInParallelMode, "'isInParallelMode' should return false" );
	}
	
	@test( "Test preExecute without overriding prepare" )
	public function testPreExecute() : Void
	{
		var myMacro : MockEmptyMacro = new MockEmptyMacro();
		
		Assert.failTrue( myMacro.wasUsed, "'wasUsed' property should return false" );
		Assert.failTrue( myMacro.isRunning, "'isRunning' property should return false" );
		Assert.assertMethodCallThrows( NullPointerException, myMacro, myMacro.preExecute, [], "" );
		
		myMacro.macroExecutor = new MockMacroExecutor();
		Assert.failTrue( myMacro.wasUsed, "'wasUsed' property should return false" );
		Assert.failTrue( myMacro.isRunning, "'isRunning' property should return false" );
		Assert.assertMethodCallThrows( VirtualMethodException, myMacro, myMacro.preExecute, [], "" );
		
		Assert.failTrue( myMacro.wasUsed, "'wasUsed' property should return false" );
		Assert.failTrue( myMacro.isRunning, "'isRunning' property should return false" );
		
		Assert.failTrue( this._macro.wasUsed, "'wasUsed' property should return false" );
		Assert.failTrue( this._macro.isRunning, "'isRunning' property should return false" );
		this._macro.preExecute();
		
		Assert.assertEquals( this._macro, this._macroExecutor.listener, "macro should listen macroexecutor" );
		Assert.assertTrue( this._macro.wasUsed, "'wasUsed' property should return true" );
		Assert.assertTrue( this._macro.isRunning, "'isRunning' property should return true" );
        Assert.assertMethodCallThrows( IllegalStateException, this._macro, this._macro.preExecute,[], "Macro should throw IllegalStateException when calling preExecute method twice" );
	}
	
	@test( "Test addComand" )
	public function testAddCommand() : Void
	{
		this._macroExecutor.returnedMapping = new CommandMapping( MockCommand );
		var commandMapping : ICommandMapping = this._macro.add( MockCommand );
		Assert.assertEquals( this._macroExecutor.returnedMapping, commandMapping, "command mapping should be returned when command class is added" );
		Assert.assertEquals( MockCommand, this._macroExecutor.lastCommandClassAdded, "command class should be passed to macroexecutor" );
	}
	
	@test( "Test addMapping" )
	public function testAddMapping() : Void
	{
		this._macroExecutor.returnedMapping = new CommandMapping( MockCommand );
		
		var mappingToAdd : CommandMapping = new CommandMapping( MockCommand );
		var commandMapping : ICommandMapping = this._macro.addMapping( mappingToAdd );
		Assert.assertEquals( this._macroExecutor.returnedMapping, commandMapping, "command mapping should be returned when mapping is added" );
		Assert.assertEquals( mappingToAdd, this._macroExecutor.lastMappingAdded, "mapping added should be passed to macroexecutor" );
	}
	
	@test( "Test execute empty macro" )
	public function testExecuteEmptyMacro() : Void
	{
		var myMacro : MockEmptyMacroWithPrepareOverrided = new MockEmptyMacroWithPrepareOverrided();
		myMacro.macroExecutor = this._macroExecutor;
		
		Assert.assertMethodCallThrows( IllegalStateException, myMacro, myMacro.execute, [], "Macro should throw IllegalStateException when calling execute without calling preExecute before" );
		myMacro.preExecute();
		var event : BasicEvent = new BasicEvent( "onTest", this );
		myMacro.execute( event );
		Assert.assertEquals( event, this._macroExecutor.eventPassedDuringExecution, "event passed to execute should be passed to macroexecutor" );
		
		var anotherEvent = new BasicEvent( "onAnotherTest", this );
		myMacro.execute( event );
		Assert.assertEquals( event, this._macroExecutor.eventPassedDuringExecution, "event passed to execute should be passed to macroexecutor" );
	}
	
	@test( "Test execute triggers 'handleComplete'" )
	public function testExecuteTriggersHandleComplet() : Void
	{
		this._macroExecutor.hasNextCommandMappingReturnValue 	= false;
		this._macroExecutor.hasRunEveryCommandReturnValue 		= true;
		
		var e : BasicEvent = new BasicEvent( "onTest", this );
		this._macro.preExecute();
		this._macro.execute( e );
		
		Assert.failTrue( this._macro.isCancelled, "'isCancelled' property should return false" );
		Assert.failTrue( this._macro.hasFailed, "'hasFailed' property should return false" );
		Assert.failTrue( this._macro.isRunning, "'isRunning' property should return false" );
		Assert.assertTrue( this._macro.wasUsed, "'wasUsed' property should return true" );
		Assert.assertTrue( this._macro.hasCompleted, "'hasCompleted' property should return true" );
	}
	
	@test( "Test with guards approved" )
	public function testWithGuardsApproved() : Void
	{
		var myMacro : MockEmptyMacroWithPrepareOverrided = new MockEmptyMacroWithPrepareOverrided();
		var macroExecutor : MacroExecutor = new MacroExecutor();
		macroExecutor.injector = new MockDependencyInjector();
		myMacro.macroExecutor = macroExecutor;

		myMacro.preExecute();
		myMacro.add( MockCommand ).withGuards( [thatWillBeApproved] );
		myMacro.execute();
		
		Assert.assertTrue( myMacro.hasCompleted, "'hasCompleted' property should return true" );
		Assert.failTrue( myMacro.hasFailed, "'hasFailed' property should return false" );
		Assert.failTrue( myMacro.isCancelled, "'isCancelled' property should return false" );
	}
	
	public function thatWillBeApproved() : Bool
	{
		return true;
	}
	
	@test( "Test with guards refused" )
	public function testWithGuardsRefused() : Void
	{
		var myMacro : MockEmptyMacroWithPrepareOverrided = new MockEmptyMacroWithPrepareOverrided();
		var macroExecutor : MacroExecutor = new MacroExecutor();
		macroExecutor.injector = new MockDependencyInjector();
		myMacro.macroExecutor = macroExecutor;

		myMacro.preExecute();
		myMacro.add( MockCommand ).withGuards( [thatWillBeRefused] );
		myMacro.execute();
		
		Assert.assertTrue( myMacro.hasFailed, "'hasFailed' property should return true" );
		Assert.failTrue( myMacro.hasCompleted, "'hasCompleted' property should return false" );
		Assert.failTrue( myMacro.isCancelled, "'isCancelled' property should return false" );
	}
	
	@test( "Test parallel mode" )
	public function testParallelMode() : Void
	{
		var myMacro : MockEmptyMacroWithPrepareOverrided = new MockEmptyMacroWithPrepareOverrided();
		var macroExecutor : MacroExecutor = new MacroExecutor();
		macroExecutor.injector = new MockDependencyInjector();
		myMacro.macroExecutor = macroExecutor;
		
		myMacro.isInParallelMode = true;
		myMacro.preExecute();
		myMacro.add( MockAsyncCommand );
		myMacro.add( MockCommand );
		
		Assert.assertEquals( 0, MockCommand.executeCallCount, "'execute' method shoud not been called" );
		myMacro.execute();
		Assert.assertEquals( 1, MockCommand.executeCallCount, "'execute' method shoud have been called once" );
	}
	
	@test( "Test sequence mode" )
	public function testSequenceMode() : Void
	{
		var myMacro : MockEmptyMacroWithPrepareOverrided = new MockEmptyMacroWithPrepareOverrided();
		var macroExecutor : MacroExecutor = new MacroExecutor();
		macroExecutor.injector = new MockDependencyInjector();
		myMacro.macroExecutor = macroExecutor;
		
		myMacro.isInSequenceMode = true;
		myMacro.preExecute();
		myMacro.add( MockAsyncCommand );
		myMacro.add( MockCommand );
		
		Assert.assertEquals( 0, MockCommand.executeCallCount, "'execute' method shoud not been called" );
		myMacro.execute();
		Assert.assertEquals( 0, MockCommand.executeCallCount, "'execute' method shoud not been called" );
	}
	
	public function thatWillBeRefused() : Bool
	{
		return false;
	}
}

private class MockAsyncCommand extends AsyncCommand
{
	override public function execute( ?e : IEvent ) : Void 
	{
		Timer.delay( this._handleComplete, 50 );
	}
}

private class MockCommand implements ICommand
{
	private var _owner : IModule;
	
	static public var executeCallCount : Int = 0;
	
	public function new()
	{
		
	}
	
	/* INTERFACE hex.control.command.ICommand */
	
	public function execute( ?e : IEvent ) : Void 
	{
		MockCommand.executeCallCount++;
	}
	
	public function getPayload() : Array<Dynamic> 
	{
		return null;
	}
	
	public function getOwner() : IModule 
	{
		return _owner;
	}
	
	public function setOwner( owner : IModule ) : Void 
	{
		this._owner = owner;
	}
}

private class MockEmptyMacro extends Macro
{
	
}

private class MockEmptyMacroWithPrepareOverrided extends Macro
{
	override private function _prepare() : Void
	{
		
	}
}

private class MockMacro extends Macro
{
	override private function _prepare() : Void
	{
		this.add( MockAsyncCommand );
		this.add( MockCommand );
	}
}

private class MockMacroExecutor implements IMacroExecutor
{
	public var eventPassedDuringExecution		: IEvent;
	public var returnedMapping					: ICommandMapping;
	public var lastCommandClassAdded 			: Class<ICommand>;
	public var lastMappingAdded 				: ICommandMapping;
	
	public var listener 						: IAsyncCommandListener;
	
	
	public var hasRunEveryCommandReturnValue 	: Bool = false;
	public var hasNextCommandMappingReturnValue : Bool = true;
	
	public function new()
	{
		
	}
	
	/* INTERFACE hex.control.macro.IMacroExecutor */
	
	public function add( commandClass : Class<ICommand> ) : ICommandMapping 
	{
		this.lastCommandClassAdded = commandClass;
		return this.returnedMapping;
	}
	
	public function executeNextCommand( ?e : IEvent ) : ICommand 
	{
		this.eventPassedDuringExecution = e;
		return null;
	}
	
	public var hasNextCommandMapping( get, null ) : Bool;
	function get_hasNextCommandMapping() : Bool 
	{
		return this.hasNextCommandMappingReturnValue;
	}
	
	public function setAsyncCommandListener( listener : IAsyncCommandListener ) : Void 
	{
		this.listener = listener;
	}
	
	public function asyncCommandCalled( asyncCommand : IAsyncCommand ) : Void 
	{
		
	}
	
	public var hasRunEveryCommand( get, null ) : Bool;
	function get_hasRunEveryCommand() : Bool 
	{
		return this.hasRunEveryCommandReturnValue;
	}
	
	public var subCommandIndex( get, null ) : Int;
	function get_subCommandIndex() : Int 
	{
		return 0;
	}
	
	public function addMapping( mapping : ICommandMapping ) : ICommandMapping 
	{
		this.lastMappingAdded = mapping;
		return returnedMapping;
	}
	
	public function toString() : String
	{
		return Stringifier.stringify( this );
	}
}