package hex.control.command;

import hex.control.async.AsyncCommand;
import hex.control.async.AsyncHandler;
import hex.control.command.CommandMapping;
import hex.control.command.ICommand;
import hex.control.payload.ExecutionPayload;
import hex.module.IModule;
import hex.unittest.assertion.Assert;

/**
 * ...
 * @author Francis Bourre
 */
class CommandMappingTest
{
	private var _commandMapping : CommandMapping;

    @setUp
    public function setUp() : Void
    {
        this._commandMapping = new CommandMapping( MockCommand );
    }

    @tearDown
    public function tearDown() : Void
    {
        this._commandMapping = null;
    }
	
	@test( "Test getCommandClass" )
    public function testGetCommandClass() : Void
    {
        Assert.equals( MockCommand, this._commandMapping.getCommandClass(), "Command class should be the same" );
    }
	
	@test( "Test guards" )
    public function testGuards() : Void
    {
        Assert.isFalse( this._commandMapping.hasGuard, "hasGuard should return false" );
		this._commandMapping.withGuards( [1, 2, 3] );
		Assert.isTrue( this._commandMapping.hasGuard, "hasGuard should return true" );
		Assert.deepEquals( [1, 2, 3], this._commandMapping.getGuards(), "guards should be the same" );
    }
	
	@test( "Test isFiredOnce" )
    public function testIsFireOnce() : Void
    {
        Assert.isFalse( this._commandMapping.isFiredOnce, "isFiredOnce should return false" );
		this._commandMapping.once();
		Assert.isTrue( this._commandMapping.isFiredOnce, "isFiredOnce should return true" );
    }
	
	@test( "Test payloads" )
    public function testPayloads() : Void
    {
        Assert.isFalse( this._commandMapping.hasPayload, "hasPayload should return false" );
		
		var stringPayload0 	: ExecutionPayload 	= new ExecutionPayload( "test0", String, "stringPayload0" );
		var stringPayload1 	: ExecutionPayload 	= new ExecutionPayload( "test1", String, "stringPayload1" );
		var stringPayload2 	: ExecutionPayload 	= new ExecutionPayload( "test2", String, "stringPayload2" );
		this._commandMapping.withPayloads( [stringPayload0, stringPayload1, stringPayload2] );
		
		Assert.isTrue( this._commandMapping.hasPayload, "hasPayload should return true" );
		Assert.deepEquals( [stringPayload0, stringPayload1, stringPayload2], this._commandMapping.getPayloads(), "payloads should be the same" );
    }
	
	@test( "Test complete handlers" )
    public function testCompleteHandlers() : Void
    {
        Assert.isFalse( this._commandMapping.hasCompleteHandler, "hasCompleteHandler should return false" );
		
		var listener0 : MockAsyncCommandListener = new MockAsyncCommandListener();
		var listener1 : MockAsyncCommandListener = new MockAsyncCommandListener();
		var listener2 : MockAsyncCommandListener = new MockAsyncCommandListener();
		
		var completeHandler0 	: AsyncHandler 	= new AsyncHandler( listener0, listener0.handler );
		var completeHandler1 	: AsyncHandler 	= new AsyncHandler( listener1, listener1.handler );
		var completeHandler2 	: AsyncHandler 	= new AsyncHandler( listener2, listener2.handler );
		
		this._commandMapping.withCompleteHandlers( completeHandler0 ).withCompleteHandlers( completeHandler1 ).withCompleteHandlers( completeHandler2 );
		
		Assert.isTrue( this._commandMapping.hasCompleteHandler, "hasCompleteHandler should return true" );
		Assert.deepEquals( [completeHandler0, completeHandler1, completeHandler2], this._commandMapping.getCompleteHandlers(), "getCompleteHandlers should be the same" );
    }
	
	@test( "Test fail handlers" )
    public function testFailHandlers() : Void
    {
        Assert.isFalse( this._commandMapping.hasFailHandler, "hasFailHandler should return false" );
		
		var listener0 : MockAsyncCommandListener = new MockAsyncCommandListener();
		var listener1 : MockAsyncCommandListener = new MockAsyncCommandListener();
		var listener2 : MockAsyncCommandListener = new MockAsyncCommandListener();
		
		var failHandler0 	: AsyncHandler 	= new AsyncHandler( listener0, listener0.handler );
		var failHandler1 	: AsyncHandler 	= new AsyncHandler( listener1, listener1.handler );
		var failHandler2 	: AsyncHandler 	= new AsyncHandler( listener2, listener2.handler );
		this._commandMapping.withFailHandlers( failHandler0 ).withFailHandlers( failHandler1 ).withFailHandlers( failHandler2 );
		
		Assert.isTrue( this._commandMapping.hasFailHandler, "hasFailHandler should return true" );
		Assert.deepEquals( [failHandler0, failHandler1, failHandler2], this._commandMapping.getFailHandlers(), "getFailHandlers should be the same" );
    }
	
	@test( "Test cancel handlers" )
    public function testCancelHandlers() : Void
    {
        Assert.isFalse( this._commandMapping.hasCancelHandler, "hasCancelHandler should return false" );
		
		var listener0 : MockAsyncCommandListener = new MockAsyncCommandListener();
		var listener1 : MockAsyncCommandListener = new MockAsyncCommandListener();
		var listener2 : MockAsyncCommandListener = new MockAsyncCommandListener();
		
		var cancelHandler0 	: AsyncHandler 	= new AsyncHandler( listener0, listener0.handler );
		var cancelHandler1 	: AsyncHandler 	= new AsyncHandler( listener1, listener1.handler );
		var cancelHandler2 	: AsyncHandler 	= new AsyncHandler( listener2, listener2.handler );
		this._commandMapping.withCancelHandlers( cancelHandler0 ).withCancelHandlers( cancelHandler1 ).withCancelHandlers( cancelHandler2 );
		
		Assert.isTrue( this._commandMapping.hasCancelHandler, "hasCancelHandler should return true" );
		Assert.deepEquals( [cancelHandler0, cancelHandler1, cancelHandler2], this._commandMapping.getCancelHandlers(), "getCancelHandlers should be the same" );
    }
}

private class MockAsyncCommandListener
{
	public function new ()
	{
		
	}
	
	public function handler( command : AsyncCommand ) : Void
	{
		
	}
}

private class MockCommand implements ICommand
{
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
		return null;
	}
	
	public function setOwner( owner : IModule ) : Void 
	{
		
	}
}