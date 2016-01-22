package hex.control.macro;

import haxe.Timer;
import hex.control.async.AsyncCommand;
import hex.control.async.AsyncHandler;
import hex.control.async.IAsyncCommandListener;
import hex.control.command.CommandMapping;
import hex.control.command.ICommand;
import hex.control.command.ICommandMapping;
import hex.control.macro.IMacroExecutor;
import hex.control.macro.MacroExecutor;
import hex.control.payload.ExecutionPayload;
import hex.control.Request;
import hex.error.IllegalStateException;
import hex.MockDependencyInjector;
import hex.module.IModule;
import hex.module.Module;
import hex.unittest.assertion.Assert;
import hex.unittest.runner.MethodRunner;

/**
 * ...
 * @author Francis Bourre
 */
class MacroExecutorTest
{
	private var _macroExecutor 		: MacroExecutor;
    private var _injector     		: MockDependencyInjectorForMapping;
    private var _module     		: IModule;
    private var _mockMacro     		: MockMacroListener;

    @Before
    public function setUp() : Void
    {
		this._injector 			= new MockDependencyInjectorForMapping();
		this._module 			= new Module();
        this._macroExecutor 	= new MacroExecutor();
        this._mockMacro 		= new MockMacroListener( this._macroExecutor );
		this._macroExecutor.setAsyncCommandListener( this._mockMacro );
		
		this._macroExecutor.injector = this._injector;
    }

    @After
    public function tearDown() : Void
    {
		this._injector 			= null;
		this._module 			= null;
        this._macroExecutor 	= null;
        this._mockMacro 		= null;
    }
	
	@Test( "Test subCommandIndex" )
    public function testSubCommandIndex() : Void
    {
		Assert.equals( 0, this._macroExecutor.subCommandIndex, "'subCommandIndex' should return 0" );
		this._macroExecutor.add( MockAsyncCommand );
		this._macroExecutor.executeNextCommand();
		Assert.equals( 1, this._macroExecutor.subCommandIndex, "'subCommandIndex' should return 1" );
	}
	
	@Test( "Test hasNextCommandMapping" )
    public function testHasNextCommandMapping() : Void
    {
		Assert.isFalse( this._macroExecutor.hasNextCommandMapping, "'hasNextCommandMapping' should return false" );
		this._macroExecutor.add( MockAsyncCommand );
		Assert.isTrue( this._macroExecutor.hasNextCommandMapping, "'hasNextCommandMapping' should return true" );
		this._macroExecutor.executeNextCommand();
		Assert.isFalse( this._macroExecutor.hasNextCommandMapping, "'hasNextCommandMapping' should return false" );
	}
	
	@Async( "Test hasRunEveryCommand" )
    public function testHasRunEveryCommand() : Void
    {
		Assert.isTrue( this._macroExecutor.hasRunEveryCommand, "'hasRunEveryCommand' should return true" );
		this._macroExecutor.add( MockCommand );
		Assert.isFalse( this._macroExecutor.hasRunEveryCommand, "'hasRunEveryCommand' should return false" );
		this._macroExecutor.executeNextCommand();
		Assert.isTrue( this._macroExecutor.hasRunEveryCommand, "'hasRunEveryCommand' should return true" );
		this._macroExecutor.add( MockAsyncCommand );
		Assert.isFalse( this._macroExecutor.hasRunEveryCommand, "'hasRunEveryCommand' should return false" );
		this._macroExecutor.executeNextCommand();
		Timer.delay( MethodRunner.asyncHandler( this._onTestHasRunEveryCommand ), 100 );
	}
	
	@Test( "Test executeNextCommand" )
    public function testExecuteNextCommand() : Void
    {
		this._macroExecutor.add( MockCommand );
		this._macroExecutor.add( MockAsyncCommand );
		var command : ICommand = this._macroExecutor.executeNextCommand();
		Assert.isInstanceOf( command, MockCommand, "command should be typed 'MockCommand'" );
		command = this._macroExecutor.executeNextCommand();
		Assert.isInstanceOf( command, MockAsyncCommand, "command should be typed 'MockCommand'" );
	}
	
	@Test( "Test asyncCommandCalled" )
    public function testAsyncCommandCalled() : Void
    {
		Assert.methodCallThrows( IllegalStateException, this._macroExecutor, this._macroExecutor.asyncCommandCalled, [ new AsyncCommand() ], "asyncCommandCalled should throw IllegalStateException" );
	}
	
	private function _onTestHasRunEveryCommand() : Void
	{
		Assert.isTrue( this._macroExecutor.hasRunEveryCommand, "'hasRunEveryCommand' should return true" );
	}
	
	@Test( "Test add" )
    public function testAdd() : Void
    {
		Assert.isFalse( this._macroExecutor.hasNextCommandMapping, "'hasNextCommandMapping' should return false" );
		
		var commandMapping : ICommandMapping = this._macroExecutor.add( MockAsyncCommand );
		Assert.equals( MockAsyncCommand, commandMapping.getCommandClass(), "'add' should return expected mapping with right same command class" );
		Assert.equals( 0, this._macroExecutor.subCommandIndex, "'subCommandIndex' should return 0" );
		Assert.isTrue( this._macroExecutor.hasNextCommandMapping, "'hasNextCommandMapping' should return true" );
		Assert.isFalse( this._macroExecutor.hasRunEveryCommand, "'hasRunEveryCommand' should return false" );
	}
	
	@Test( "Test add mapping" )
    public function testAddMapping() : Void
    {
		Assert.isFalse( this._macroExecutor.hasNextCommandMapping, "'hasNextCommandMapping' should return false" );
		
		var commandMapping : ICommandMapping = new CommandMapping( MockAsyncCommand );
		var returnedCommandMapping : ICommandMapping = this._macroExecutor.addMapping( commandMapping );
		Assert.equals( commandMapping, returnedCommandMapping, "'addMapping' should return ethe same command mapping" );
		Assert.equals( 0, this._macroExecutor.subCommandIndex, "'subCommandIndex' should return 0" );
		Assert.isTrue( this._macroExecutor.hasNextCommandMapping, "'hasNextCommandMapping' should return true" );
		Assert.isFalse( this._macroExecutor.hasRunEveryCommand, "'hasRunEveryCommand' should return false" );
	}
	
	@Test( "Test command execution" )
    public function testExecuteCommand() : Void
    {
		var commandMapping : ICommandMapping = new CommandMapping( MockAsyncCommandForTestingExecution );
		
		var listener0 			: ASyncCommandListener 				= new ASyncCommandListener();
		var listener1 			: ASyncCommandListener 				= new ASyncCommandListener();
		var listener2 			: ASyncCommandListener 				= new ASyncCommandListener();
		
		var completeHandlers 	: Array<AsyncCommand->Void> 	= [listener0.onAsyncCommandComplete, listener1.onAsyncCommandComplete, listener2.onAsyncCommandComplete];
		var failHandlers 		: Array<AsyncCommand->Void> 	= [listener0.onAsyncCommandFail, listener1.onAsyncCommandFail, listener2.onAsyncCommandFail];
		var cancelHandlers 		: Array<AsyncCommand->Void> 	= [listener0.onAsyncCommandCancel, listener1.onAsyncCommandCancel, listener2.onAsyncCommandCancel];
		
		commandMapping	.withCompleteHandlers( new AsyncHandler( listener0, listener0.onAsyncCommandComplete ) )
						.withCompleteHandlers( new AsyncHandler( listener1, listener1.onAsyncCommandComplete ) )
						.withCompleteHandlers( new AsyncHandler( listener2, listener2.onAsyncCommandComplete ) );
						
		commandMapping	.withFailHandlers( new AsyncHandler( listener0, listener0.onAsyncCommandFail ) )
						.withFailHandlers( new AsyncHandler( listener1, listener1.onAsyncCommandFail ) )
						.withFailHandlers( new AsyncHandler( listener2, listener2.onAsyncCommandFail ) );
						
		commandMapping	.withCancelHandlers( new AsyncHandler( listener0, listener0.onAsyncCommandCancel ) )
						.withCancelHandlers( new AsyncHandler( listener1, listener1.onAsyncCommandCancel ) )
						.withCancelHandlers( new AsyncHandler( listener2, listener2.onAsyncCommandCancel ) );
		
		var mockImplementation 	: MockImplementation 				= new MockImplementation( "mockImplementation" );
		var mockPayload 		: ExecutionPayload 					= new ExecutionPayload( mockImplementation, IMockType, "mockPayload" );
		commandMapping.withPayloads( [mockPayload] );
		
		var stringPayload 				: ExecutionPayload 			= new ExecutionPayload( "test", String, "stringPayload" );
		var anotherMockImplementation 	: MockImplementation 		= new MockImplementation( "anotherMockImplementation" );
		var anotherMockPayload 			: ExecutionPayload 			= new ExecutionPayload( anotherMockImplementation, IMockType, "anotherMockPayload" );
		var payloads 					: Array<ExecutionPayload> 	= [ stringPayload, anotherMockPayload ];
		
		var request : Request = new Request( payloads );
		var command : ICommand = this._macroExecutor.executeCommand( commandMapping, request );
		
		Assert.isNotNull( command, "'command' should not be null" );
		Assert.isInstanceOf( command, MockAsyncCommandForTestingExecution, "'command' shouldbe typed 'MockAsyncCommandForTestingExecution'" );
		
		Assert.equals( 1, MockAsyncCommandForTestingExecution.executeCallCount, "preExecute should be called once" );
		Assert.equals( 1, MockAsyncCommandForTestingExecution.preExecuteCallCount, "execute should be called once" );
		
//		Assert.assertEquals( this._module, MockAsyncCommandForTestingExecution.owner, "owner should be the same" );
		Assert.equals( request, MockAsyncCommandForTestingExecution.request, "request should be the same" );
		
		Assert.deepEquals( request, MockAsyncCommandForTestingExecution.request, "request should be the same" );
		
		Assert.arrayContains( completeHandlers, MockAsyncCommandForTestingExecution.completeHandlers, "complete handlers should be added to async command instance" );
		Assert.arrayContains( failHandlers, MockAsyncCommandForTestingExecution.failHandlers, "fail handlers should be added to async command instance" );
		Assert.arrayContains( cancelHandlers, MockAsyncCommandForTestingExecution.cancelHandlers, "cancel handlers should be added to async command instance" );
		
		Assert.equals( 1, this._injector.getOrCreateNewInstanceCallCount, "'injector.getOrCreateNewInstance' method should be called once" );
		Assert.equals( MockAsyncCommandForTestingExecution, this._injector.getOrCreateNewInstanceCallParameter, "'injector.getOrCreateNewInstance' parameter should be command class" );
		
		Assert.deepEquals( 	[ [mockImplementation, IMockType, "mockPayload"], ["test", String, "stringPayload"], [anotherMockImplementation, IMockType, "anotherMockPayload"] ], 
									this._injector.mappedPayloads,
									"'CommandExecutor.mapPayload' should map right values" );
									
		Assert.deepEquals( 	[ [IMockType, "mockPayload"], [String, "stringPayload"], [IMockType, "anotherMockPayload"] ], 
									this._injector.unmappedPayloads,
									"'CommandExecutor.unmapPayload' should unmap right values" );
	}
	
	@Test( "Test command execution with approved guards" )
    public function testExecuteCommandWithApprovedGuards() : Void
    {
		var commandMapping : ICommandMapping = new CommandMapping( MockCommand ).withGuards( [thatWillBeApproved] );
		var command : ICommand = this._macroExecutor.executeCommand( commandMapping );
		Assert.isNotNull( command, "'command' should not be null" );
		Assert.isInstanceOf( command, MockCommand, "'command' shouldbe typed 'MockCommand'" );
	}
	
	@Test( "Test command execution with refused guards" )
    public function testExecuteCommandWithRefusedGuards() : Void
    {
		var failListener : MockMacroFailListener = new MockMacroFailListener();
		this._macroExecutor.setAsyncCommandListener( failListener );
		
		var commandMapping : ICommandMapping = new CommandMapping( MockCommand ).withGuards( [thatWillBeRefused] );
		var command : ICommand = this._macroExecutor.executeCommand( commandMapping );
		Assert.isNull( command, "'command' should be null" );
		Assert.equals( 1, failListener.onAsyncCommandFailCallCount, "'onAsyncCommandFail' method should be called once" );
		//Assert.assertIsType( failListener.failEvent, AsyncCommandEvent, "'onAsyncCommandFail' method should be called once" );
	}
	
	public function thatWillBeApproved() : Bool
	{
		return true;
	}

	public function thatWillBeRefused() : Bool
	{
		return false;
	}
}

private class MockAsyncCommandForTestingExecution extends MockAsyncCommand
{
	static public var executeCallCount 		: Int = 0;
	static public var preExecuteCallCount 	: Int = 0;
	
	static public var request 				: Request;
	static public var owner 				: IModule;
	
	static public var completeHandlers 		: Array<AsyncCommand->Void> = [];
	static public var failHandlers 			: Array<AsyncCommand->Void> = [];
	static public var cancelHandlers 		: Array<AsyncCommand->Void> = [];
	
	override public function setOwner( owner : IModule ) : Void 
	{
		MockAsyncCommandForTestingExecution.owner = owner;
	}
	
	override public function preExecute() : Void 
	{
		MockAsyncCommandForTestingExecution.preExecuteCallCount++;
	}
	
	override public function execute( ?request : Request ) : Void 
	{
		MockAsyncCommandForTestingExecution.executeCallCount++;
		MockAsyncCommandForTestingExecution.request = request;
	}
	
	override public function addCompleteHandler( scope : Dynamic, callback : AsyncCommand->Void ) : Void
	{
		MockAsyncCommandForTestingExecution.completeHandlers.push( callback );
	}
	
	override public function addFailHandler( scope : Dynamic, callback : AsyncCommand->Void ) : Void
	{
		MockAsyncCommandForTestingExecution.failHandlers.push( callback );
	}
	
	override public function addCancelHandler( scope : Dynamic, callback : AsyncCommand->Void ) : Void
	{
		MockAsyncCommandForTestingExecution.cancelHandlers.push( callback );
	}
}

private class MockAsyncCommand extends AsyncCommand
{
	override public function execute( ?request : Request ) : Void 
	{
		Timer.delay( this._handleComplete, 50 );
	}
}

private class MockCommand implements ICommand
{
	private var _owner : IModule;
	
	public function new()
	{
		
	}

	public function execute( ?request : Request ) : Void 
	{
		
	}
	
	public function getPayload() : Array<Dynamic> 
	{
		return null;
	}
	
	public function getOwner() : IModule 
	{
		return this._owner;
	}
	
	public function setOwner( owner : IModule ) : Void 
	{
		this._owner = owner;
	}
}

private class MockMacroFailListener extends ASyncCommandListener
{
	public var onAsyncCommandFailCallCount : Int = 0;
	public var failCommand : AsyncCommand;
	
	override public function onAsyncCommandFail( cmd : AsyncCommand ) : Void 
	{
		this.onAsyncCommandFailCallCount++;
		this.failCommand = cmd;
	}
}

private class MockMacroListener extends ASyncCommandListener
{
	private var _macroExecutor : IMacroExecutor;
	
	public function new( macroExecutor : IMacroExecutor )
	{
		this._macroExecutor = macroExecutor;
		super();
	}
	
	override public function onAsyncCommandComplete( cmd : AsyncCommand ) : Void
	{
		this._macroExecutor.asyncCommandCalled( cmd );
	}
	
	override public function onAsyncCommandFail( cmd : AsyncCommand ) : Void
	{
		this._macroExecutor.asyncCommandCalled( cmd );
	}
	
	override public function onAsyncCommandCancel( cmd : AsyncCommand ) : Void 
	{
		this._macroExecutor.asyncCommandCalled( cmd );
	}
}

private class ASyncCommandListener implements IAsyncCommandListener
{
	public function new()
	{
		
	}
	
	public function onAsyncCommandComplete( cmd : AsyncCommand ) : Void 
	{
		
	}
	
	public function onAsyncCommandFail( cmd : AsyncCommand ) : Void 
	{
		
	}
	
	public function onAsyncCommandCancel( cmd : AsyncCommand ) : Void 
	{
		
	}
}

private class MockDependencyInjectorForMapping extends MockDependencyInjector
{
	public var getOrCreateNewInstanceCallCount 		: Int = 0;
	public var getOrCreateNewInstanceCallParameter 	: Class<Dynamic>;
	public var mappedPayloads 						: Array<Array<Dynamic>> = [];
	public var unmappedPayloads 					: Array<Array<Dynamic>> = [];
	
	override public function mapToValue( clazz : Class<Dynamic>, value : Dynamic, ?name : String = '' ) : Void 
	{
		this.mappedPayloads.push( [ value, clazz, name ] );
	}
	
	override public function unmap( type : Class<Dynamic>, name : String = '' ) : Void 
	{
		this.unmappedPayloads.push( [ type, name ] );
	}
	
	override public function getOrCreateNewInstance( type : Class<Dynamic> ) : Dynamic 
	{
		this.getOrCreateNewInstanceCallCount++;
		this.getOrCreateNewInstanceCallParameter = type;
		return Type.createInstance( type, [] );
	}
}

private class MockImplementation implements IMockType
{
	public var name : String;
	
	public function new( name : String )
	{
		this.name = name;
	}
}

private interface IMockType
{
	
}