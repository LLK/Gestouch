package org.gestouch.gestures
{
	import flash.geom.Point;
	import org.gestouch.core.gestouch_internal;
	import org.gestouch.core.GestureState;
	import org.gestouch.core.Touch;

	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	use namespace gestouch_internal;


	/**
	 * 
	 * @author Pavel fljot
	 */
	public class TapGesture extends AbstractDiscreteGesture
	{
		public var numTouchesRequired:uint = 1;
		public var numTapsRequired:uint = 1;
		public var slop:Number = Gesture.DEFAULT_SLOP << 2;//iOS has 45px for 132 dpi screen
		public var maxTapDelay:uint = 400;
		public var maxTapDuration:uint = 1500;
		public var maxTapDistance:Number = Gesture.DEFAULT_SLOP << 2;
		
		protected var _timer:Timer;
		protected var _numTouchesRequiredReached:Boolean;
		protected var _tapCounter:uint = 0;
		protected var _touchBeginLocations:Vector.<Point> = new Vector.<Point>();
		protected var firstTouchTarget:Object;
		
		
		public function TapGesture(target:Object = null)
		{
			super(target);
		}
		
		
		
		
		// --------------------------------------------------------------------------
		//
		// Public methods
		//
		// --------------------------------------------------------------------------
		
		override public function reflect():Class
		{
			return TapGesture;
		}
		
		
		override public function reset():void
		{
			_numTouchesRequiredReached = false;
			_tapCounter = 0;
			_timer.reset();
			_touchBeginLocations.length = 0;
			
			super.reset();
		}
		
		
		override gestouch_internal function canPreventGesture(preventedGesture:Gesture):Boolean
		{
			if (preventedGesture is TapGesture &&
				(preventedGesture as TapGesture).numTapsRequired > this.numTapsRequired)
			{
				return false;
			}
			return true;
		}
		
		
		
		
		// --------------------------------------------------------------------------
		//
		// Protected methods
		//
		// --------------------------------------------------------------------------
		
		override protected function preinit():void
		{
			super.preinit();
			
			_timer = new Timer(maxTapDelay, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, timer_timerCompleteHandler);
		}
		
		
		override protected function onTouchBegin(touch:Touch):void
		{
			if (touchesCount > numTouchesRequired)
			{
				failOrIgnoreTouch(touch);
				return;
			}
			
			if (touchesCount == 1)
			{
				_timer.reset();
				_timer.delay = maxTapDuration;
				_timer.start();
				firstTouchTarget = touch.target;
			}
			
			if (numTapsRequired > 1)
			{
				if (_tapCounter == 0)
				{
					// Save touch begin locations to check
					_touchBeginLocations.push(touch.location);
				}
				else
				{
					// Quite a dirty check, but should work in most cases
					var found:Boolean = false;
					for each (var loc:Point in _touchBeginLocations)
					{
						// current touch should be near any previous one
						if (Point.distance(touch.location, loc) <= maxTapDistance)
						{
							found = true;
							break;
						}
					}

					if (!found)
					{
						setState(GestureState.FAILED);
						return;
					}
				}
			}
			
			if (touchesCount == numTouchesRequired)
			{
				_numTouchesRequiredReached = true;
				updateLocation();
			}
		}
		
		
		override protected function onTouchMove(touch:Touch):void
		{
			if (slop >= 0 && touch.locationOffset.length > slop)
			{
				setState(GestureState.FAILED);
			}
		}
		
		
		override protected function onTouchEnd(touch:Touch):void
		{
			if (!_numTouchesRequiredReached)
			{
				setState(GestureState.FAILED);
				firstTouchTarget = null;
			}
			else if (touchesCount == 0)
			{
				// reset flag for the next "full press" cycle
				_numTouchesRequiredReached = false;

				_tapCounter++;
				_timer.reset();
				
				if (_tapCounter == numTapsRequired)
				{
					if (numTouchesRequired == 1 && firstTouchTarget && touch.target != firstTouchTarget) {
						firstTouchTarget = null;
						return;
					}

					setState(GestureState.RECOGNIZED);
				}
				else
				{
					_timer.delay = maxTapDelay;
					_timer.start();
				}
			}
		}
		
		
		
		
		//--------------------------------------------------------------------------
		//
		//  Event handlers
		//
		//--------------------------------------------------------------------------
		
		protected function timer_timerCompleteHandler(event:TimerEvent):void
		{
			if (state == GestureState.POSSIBLE)
			{
				setState(GestureState.FAILED);
			}
		}
	}
}