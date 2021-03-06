package hex.control;

import hex.control.FrontController;
import hex.control.command.ICommand;
import hex.control.command.ICommandMapping;
import hex.control.payload.ExecutionPayload;
import hex.core.IApplicationContext;
import hex.di.IDependencyInjector;
import hex.di.IInjectorListener;
import hex.di.provider.IDependencyProvider;
import hex.domain.Domain;
import hex.event.Dispatcher;
import hex.event.IDispatcher;
import hex.event.MessageType;
import hex.log.ILogger;
import hex.module.IContextModule;
import hex.module.IModule;
import hex.unittest.assertion.Assert;

/**
 * ...
 * @author Francis Bourre
 */
class FrontControllerTest
{
	var _dispatcher 		: IDispatcher<{}>;
    var _injector   		: MockDependencyInjector;
	var _module     		: MockModule;
	var _frontcontroller 	: FrontController;

    @Before
    public function setUp() : Void
    {
		this._dispatcher 		= new Dispatcher<{}>();
		this._injector 			= new MockDependencyInjector();
		this._module 			= new MockModule();
        this._frontcontroller 	= new FrontController( this._dispatcher, this._injector, this._module );
    }

    @After
    public function tearDown() : Void
    {
		this._dispatcher 		= null;
		this._injector 			= null;
		this._module 			= null;
        this._frontcontroller 	= null;
    }
	
	@Test( "Test map" )
    public function testMap() : Void
    {
		var messageType = new MessageType( "messageType" );
		var commandMapping : ICommandMapping = this._frontcontroller.map( messageType, MockCommand );
		Assert.equals( MockCommand, commandMapping.getCommandClass(), "Command class should be the same" );
		Assert.isTrue( this._frontcontroller.isRegisteredWithKey( messageType ), "messageType should be registered" );
		Assert.equals( commandMapping, this._frontcontroller.locate( messageType ), "command mapping should be associated to messageType" );
    }
	
	@Test( "Test unmap" )
    public function testUnmap() : Void
    {
		var messageType = new MessageType( "messageType" );
		var commandMapping0 : ICommandMapping = this._frontcontroller.map( messageType, MockCommand );
		var commandMapping1 : ICommandMapping = this._frontcontroller.unmap( messageType );
		
		Assert.equals( commandMapping0, commandMapping1, "Command mappings should be the same" );
		Assert.isFalse( this._frontcontroller.isRegisteredWithKey( messageType ), "messageType should not be registered anymore" );
    }
	
	@Test( "Functional test of request handling" )
    public function testRequestHandling() : Void
    {
		var messageType = new MessageType( "messageType" );
		var request = new Request();
		this._frontcontroller.map( messageType, MockCommand );
		
		this._dispatcher.dispatch( messageType, [request] );
		
		Assert.equals( 1, MockCommand.executeCallCount, "Command execution should happenned once" );
		
		var anotherMessageType = new MessageType( "anotherMessageType" );
		var anotherRequest = new Request();
		this._dispatcher.dispatch( anotherMessageType, [anotherRequest] );
		
		Assert.equals( 1, MockCommand.executeCallCount, "Command execution should happenned once" );
		
		this._frontcontroller.map( anotherMessageType, MockCommand );
		this._dispatcher.dispatch( anotherMessageType, [anotherRequest] );
		
		Assert.equals( 2, MockCommand.executeCallCount, "Command execution should happenned twice" );
	}
	
	@Test( "Functional test of request handling from a macro" )
    public function testRequestHandlingFromMacro() : Void
    {
		var messageType = new MessageType( "messageType" );
		var request = new Request();
		this._frontcontroller.map( messageType, MockMacroForFrontcontroller );
		
		this._dispatcher.dispatch( messageType, [request] );
		
		Assert.equals( 1, MockMacroForFrontcontroller.executeCallCount, "Command execution should happenned once" );
		Assert.equals( request, MockMacroForFrontcontroller.requestParameter, "request received by the command should be the same that was dispatched" );
		
		var anotherMessageType = new MessageType( "anotherMessageType" );
		var anotherRequest = new Request();
		this._dispatcher.dispatch( anotherMessageType, [anotherRequest] );
		
		Assert.equals( 1, MockMacroForFrontcontroller.executeCallCount, "Command execution should happenned once" );
		Assert.equals( request, MockMacroForFrontcontroller.requestParameter, "request received by the command should be the same that was dispatched" );
		
		this._frontcontroller.map( anotherMessageType, MockMacroForFrontcontroller );
		this._dispatcher.dispatch( anotherMessageType, [anotherRequest] );
		
		Assert.equals( 2, MockMacroForFrontcontroller.executeCallCount, "Command execution should happenned twice" );
		Assert.equals( anotherRequest, MockMacroForFrontcontroller.requestParameter, "request received by the command should be the same that was dispatched" );
	}
}

private class MockCommand implements ICommand
{
	public static var executeCallCount 				: Int = 0;
	public var executeMethodName( default, null ) 	: String = "execute";
	
	public function new(){}
	
	public function getLogger() : ILogger
	{
		return this.getOwner().getLogger();
	}
	
	public function execute() : Void 
	{
		MockCommand.executeCallCount++;
	}
	
	public function getResult() : Array<Dynamic> 
	{
		return null;
	}
	
	public function getReturnedExecutionPayload() : Array<ExecutionPayload>
	{
		return null;
	}
	
	public function getOwner() : IModule 
	{
		return null;
	}
	
	public function setOwner( owner : IContextModule ) : Void 
	{
		
	}
}

private class MockModule implements IModule
{
	public function new()
	{
		
	}
	
	public function initialize( context : IApplicationContext ) : Void 
	{
		
	}
	
	@:isVar public var isInitialized( get, null ) : Bool;
	function get_isInitialized() : Bool
	{
		return false;
	}
	
	public function release() : Void 
	{
		
	}

	@:isVar public var isReleased( get, null ) : Bool;
	public function get_isReleased() : Bool
	{
		return false;
	}
	
	public function dispatchPublicMessage( messageType : MessageType, ?data : Array<Dynamic> ) : Void
	{
		
	}
	
	public function addHandler( messageType : MessageType, scope : Dynamic, callback : Dynamic ) : Void
	{
		
	}
	
	public function removeHandler( messageType : MessageType, scope : Dynamic, callback : Dynamic ) : Void
	{
		
	}
	
	public function getDomain() : Domain 
	{
		return null;
	}
	
	public function getInjector() : IDependencyInjector
	{
		return null;
	}
	
	public function getLogger() : ILogger
	{
		return null;
	}
}

private class MockDependencyInjector implements IDependencyInjector
{
	public function new()
	{
		
	}
	
	public function hasMapping( type : Class<Dynamic>, name : String = '' ) : Bool 
	{
		return false;
	}
	
	public function hasDirectMapping( type : Class<Dynamic>, name:String = '' ) : Bool 
	{
		return false;
	}
	
	public function satisfies( type : Class<Dynamic>, name : String = '' ) : Bool 
	{
		return false;
	}
	
	public function injectInto( target : Dynamic ) : Void 
	{
		
	}
	
	public function getInstance<T>( type : Class<T>, name : String = '', targetType : Class<Dynamic> = null ) : T 
	{
		return null;
	}
	
	public function getInstanceWithClassName<T>( className : String, name : String = '', targetType : Class<Dynamic> = null, shouldThrowAnError : Bool = true ) : T
	{
		return null;
	}
	
	public function getOrCreateNewInstance<T>( type : Class<T> ) : T 
	{
		return cast Type.createInstance( type, [] );
	}
	
	public function instantiateUnmapped<T>( type : Class<T> ) : T 
	{
		return null;
	}
	
	public function destroyInstance( instance : Dynamic ) : Void 
	{
		
	}
	
	public function mapToValue( clazz : Class<Dynamic>, value : Dynamic, ?name : String = '' ) : Void 
	{
		
	}
	
	public function mapToType( clazz : Class<Dynamic>, type : Class<Dynamic>, name : String = '' ) : Void 
	{
		
	}
	
	public function mapToSingleton( clazz : Class<Dynamic>, type : Class<Dynamic>, name : String = '' ) : Void 
	{
		
	}
	
	public function unmap( type : Class<Dynamic>, name : String = '' ) : Void 
	{
		
	}

	public function addListener( listener : IInjectorListener ) : Bool
	{
		return false;
	}

	public function removeListener( listener : IInjectorListener ) : Bool
	{
		return false;
	}
	
	public function getProvider<T>(className : String, name : String = '' ) : IDependencyProvider<T>
	{
		return null;
	}
	
	public function mapClassNameToValue( className : String, value : Dynamic, ?name : String = '' ) : Void
	{
		
	}

    public function mapClassNameToType( className : String, type : Class<Dynamic>, name:String = '' ) : Void
	{
		
	}

    public function mapClassNameToSingleton( className : String, type : Class<Dynamic>, name:String = '' ) : Void
	{
		
	}
	
	public function unmapClassName( className : String, name : String = '' ) : Void
	{
		
	}
}