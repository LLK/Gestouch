package org.gestouch.core
{
/**
	 * @author Pavel fljot
	 */
	public interface IDisplayListAdapter extends IGestureTargetAdapter
	{
		function getHierarchy(target:Object, touch:Touch):Vector.<Object>;
		
		function reflect():Class;
	}
}