package hex.service;

import hex.service.ServiceEvent;
import hex.unittest.assertion.Assert;
import hex.service.stateless.MockStatelessService;

/**
 * ...
 * @author Francis Bourre
 */
class ServiceEventTest
{
	@test( "Test 'type' parameter passed to constructor" )
    public function testType() : Void
    {
        var type : String = "type";
		var target : MockStatelessService = new MockStatelessService();
        var e : ServiceEvent = new ServiceEvent( type, target );
        Assert.assertEquals( type, e.type, "'type' property should be the same passed to constructor" );
    }

    @test( "Test 'target' parameter passed to constructor" )
    public function testTarget() : Void
    {
        var target : MockStatelessService = new MockStatelessService();
        var e : ServiceEvent = new ServiceEvent( "", target );

        Assert.assertEquals( target, e.target, "'target' property should be the same passed to constructor" );
    }

    @test( "Test clone method" )
    public function testClone() : Void
    {
        var type : String = "type";
        var target : MockStatelessService = new MockStatelessService();
        var e : ServiceEvent = new ServiceEvent( type, target );
        var clonedEvent : ServiceEvent = cast e.clone();

        Assert.assertEquals( type, clonedEvent.type, "'clone' method should return cloned event with same 'type' property" );
        Assert.assertEquals( target, clonedEvent.target, "'clone' method should return cloned event with same 'target' property" );
    }
	
	@test( "Test 'service' parameter passed to constructor" )
    public function testServiceParameter() : Void
    {
		var service : MockStatelessService = new MockStatelessService();
        var e : ServiceEvent = new ServiceEvent( "eventType", service );

        Assert.assertEquals( service, e.getService(), "'getStatelessService' accessor should return property passed to constructor" );
    }
}