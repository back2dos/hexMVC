package hex.service;

import hex.error.VirtualMethodException;
import hex.service.ServiceConfiguration;
import hex.unittest.assertion.Assert;

/**
 * ...
 * @author Francis Bourre
 */
class AbstractServiceTest
{
	@test( "Test 'getConfiguration' accessor" )
    public function testGetConfiguration() : Void
    {
        var configuration : ServiceConfiguration = new ServiceConfiguration();
        var service : MockServiceWithConfigurationSetter = new MockServiceWithConfigurationSetter();
		
		Assert.assertIsNull( service.getConfiguration(), "configuration should be null by default" );
		
		service.setConfiguration( configuration );
        Assert.assertEquals( configuration, service.getConfiguration(), "configuration should be retrieved from getter" );
    }
	
	@test( "Test virtual methods" )
    public function testVirtualMethods() : Void
    {
		var service : MockService = new MockService();
		Assert.assertMethodCallThrows( VirtualMethodException, service, service.createConfiguration, [], "'createConfiguration' call should throw an exception" );
		Assert.assertMethodCallThrows( VirtualMethodException, service, service.setConfiguration, [null], "'setConfiguration' call should throw an exception" );
		Assert.assertMethodCallThrows( VirtualMethodException, service, service.addHandler, [null, null], "'addHandler' call should throw an exception" );
		Assert.assertMethodCallThrows( VirtualMethodException, service, service.removeHandler, [null, null], "'method' removeHandler should throw an exception" );
		Assert.assertMethodCallThrows( VirtualMethodException, service, service.release, [], "'method' release should throw an exception" );
	}
}

private class MockServiceWithConfigurationSetter extends MockService
{
	public function new()
	{
		super();
	}
	
	override public function setConfiguration( configuration : ServiceConfiguration ) : Void
	{
		this._configuration = configuration;
	}
}