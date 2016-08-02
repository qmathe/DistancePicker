/**
	Copyright (C) 2014 Quentin Mathe
 
	Date:  November 2014
	License:  MIT
 */

import Foundation
import UIKit
import MapKit

func usesMetricSystem() -> Bool {
	let usesMetric = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem)!.boolValue as Bool
	let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
	
	return usesMetric && countryCode != "GB"
}

func metersFromMiles(miles: Double) -> Double {
	if miles == DBL_MAX {
		return DBL_MAX
	}
	return miles * 1609.344
}

func milesFromMeters(meters: Double) -> Double {
	if meters == DBL_MAX {
		return DBL_MAX
	}
	return meters * 0.000621371192
}

public class DistancePicker : UIControl, UIDynamicAnimatorDelegate {
	
	// MARK: - Cached State

	var formatter = MKDistanceFormatter()
	
	// MARK: - Target/Action State
	
	weak var target: AnyObject?
	var action: Selector?

	// MARK: - Content State

	var marks: [Double] = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 5000, 10000, 20000, 30000, 50000, 100000, 200000, DBL_MAX] {
		didSet {
			formattedMarks = formattedMarksFromMarks(marks)
		}
	}
	var formattedMarks: [String]!
	var usesMetricSystem: Bool = true {
		didSet {
			formatter.units = usesMetricSystem ? .Metric : .Imperial
			formattedMarks = formattedMarksFromMarks(marks)
		}
	}

	// MARK: - Appearance State

	// Due to a bug in Swift 2.2, we have to call init explicity.
	//
	// Was using systemFontOfSize(11) previously.
	var markAttributes = [NSFontAttributeName: UIFont.init(name: "Avenir-Medium", size: 13)!,
	            NSParagraphStyleAttributeName: NSMutableParagraphStyle(),
	           NSForegroundColorAttributeName: UIColor.grayColor().colorWithAlphaComponent(0.8)]
	var markSpacing = CGFloat(50)
	var markColor = UIColor.lightGrayColor()
	var numberOfIncrementsBetweenMarks = 5
	var incrementSpacing: CGFloat {
		return markSpacing / CGFloat(numberOfIncrementsBetweenMarks)
	}
	var incrementColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
	var markLineLength: CGFloat {
		return markSpacing * CGFloat(marks.count - 1)
	}
	
	// MARK: - Selection State

	// The selected position on the mark line that starts with zero and ends 
	// with -markLineLength.
	// This position usually falls between two mark positions. We can extract
	// the lower and upper marks with floor(), ceil() or round() to round it
	// towards the closest mark.
	var selectedPosition: CGFloat {
		return bounds.width * 0.5 - offset
	}
	public var selectedMarkIndex: Int  {
		return previousMarkIndex
	}
	// The index of the mark before the selected point
	var previousMarkIndex: Int {
		let markIndex = Int(floor(selectedPosition / markSpacing))
		return markIndex > (marks.count - 1) ? marks.count - 1 : markIndex
	}
	// The index of the mark after the selected point
	var nextMarkIndex: Int {
		let markIndex = Int(ceil(selectedPosition / markSpacing))
		return markIndex > (marks.count - 1) ? marks.count - 1 : markIndex
	}
	var selectedMark: Double {
		//print("Selected mark index \(selectedMarkIndex)")
		return marks[selectedMarkIndex]
	}
	var selectedFormattedMark: String {
		return formattedMarks[selectedMarkIndex]
	}
	public var selectedIncrementIndex: Int {
		let selectedMarkPosition = CGFloat(selectedMarkIndex) * markSpacing
		let positionFromMark = selectedPosition - selectedMarkPosition
		let incrementIndex = Int(round(positionFromMark / incrementSpacing))

		return incrementIndex > (numberOfIncrementsBetweenMarks - 1) ? numberOfIncrementsBetweenMarks - 1 : incrementIndex
	}
	var selectedIncrement: Double {
		// When the next mark is the last one (infinite), we use a 1000 km as
		// our last mark value, to compute the increment on a range between
		// 200 km and 1000 km.
		let maxMarkForIncrement = Double(1000000)
		let nextMark = marks[nextMarkIndex] == DBL_MAX ? maxMarkForIncrement : marks[nextMarkIndex]
		let previousMark = marks[previousMarkIndex] == DBL_MAX ? maxMarkForIncrement : marks[previousMarkIndex]
		let incrementTotal = nextMark - previousMark
		//print("Increment total \(incrementTotal)")
		assert(incrementTotal >= 0 && incrementTotal <= maxMarkForIncrement)
		let incrementValue = incrementTotal != 0 ? incrementTotal / Double(numberOfIncrementsBetweenMarks) : Double(0)
		
		return Double(selectedIncrementIndex) * incrementValue
	}
	var selectedValue: Double {
		//print("Selected mark \(selectedMark) increment \(selectedIncrement)")
		return selectedMark == DBL_MAX ? selectedMark : selectedMark + selectedIncrement
	}
	
	// MARK: - Geometry State

	// A zero offset doesn't represent the lowest mark, since the head that 
	// selects a mark is not at the picker origin but at the bounds width middle.
	// So the selected mark for the zero offset depends on the screen size.
	//
	// At zero, the lowest is the bounds origin.
	//
	// When the offset increases, the selected mark index/value decreases.
	// When the offset descreases, the selected mark index/value increases.
	//
	// The offset doesn't shift the picker bounds origin towards the left or 
	// right, since the picker head must always be drawn in the center and
	// moving the bounds would move the picker head (putting the picker head 
	// in another layer is not so helpful since we must redraw the selected
	// increment and mark with the tint color too)
	public var offset: CGFloat = CGFloat(0) {
		didSet {
			if offset > maxOffset {
				offset = maxOffset
			}
			else if offset < minOffset {
				offset = minOffset
			}
			//print("\(offset) min: \(minOffset) max: \(maxOffset)")
			setNeedsDisplay()
		}
	}
	// The minimum offset corresponds to the infinite mark, since we move the
	// picker to the left (the offset grows towards negative numbers).
	public var minOffset: CGFloat {
		return -(markLineLength - (bounds.size.width * 0.5))
	}
	// The maximum offset corresponds to the zero mark, since we move the
	// picker to the right (the offset grows towards positive numbers).
	public var maxOffset: CGFloat {
		return bounds.size.width * 0.5
	}
	var normalizedBounds: CGRect {
		var normalizedBounds = bounds
		normalizedBounds.size.width = 1000
		return normalizedBounds
	}
	// An offset that can be saved and reloaded indepently of the distance 
	// picker bounds (e.g. when the screen is rotated or bigger/smaller)
	public var normalizedOffset: CGFloat {
		get {
			return convertOffset(offset, fromBounds: bounds, toBounds: normalizedBounds)
		}
		set {
			offset = convertOffset(newValue, fromBounds: normalizedBounds, toBounds: bounds)
		}
	}
	// Adjust the offset on resizing (this means screen rotation is supported)
	override public var frame: CGRect {
		didSet {
			offset = convertOffset(offset, fromBounds: oldValue, toBounds: frame)
    	}
	}
	
	public func convertOffset(offset: CGFloat,
	               fromBounds oldBounds: CGRect,
	                 toBounds newBounds: CGRect) -> CGFloat {
		return offset + (newBounds.size.width - oldBounds.size.width) / 2
	}

	// MARK: - Animation State

	private var dynamicItem = DynamicItem()
	var animator: UIDynamicAnimator!

	func formattedMarksFromMarks(marks: [Double]) -> [String] {
		// For non-metric system, here is how we interpret the base marks in the 
		// imperial system:
		//
		// - 100 m to 0.1 mi (~ 500 ft or ~ 150 m)
		// - 200 m to 0.2 mi (~ 1000 ft or ~ 300 m)
		//
		// This ensures the proposed distances increase in a regular manner with
		// numbers that don't appear too random (when comparing miles to meters 
		// that get used by default.)
		//
		// Note: there is no unit attached to the 'marks' property initially.
		let meterMarks = usesMetricSystem ? marks : marks.map {
			let miles = $0 == DBL_MAX ? DBL_MAX : $0 / 1000

			return metersFromMiles(miles)
		}

		return meterMarks.map {
			if $0 == DBL_MAX {
				return "∞"
			}
			
			// Distance argument must be in meters
			return self.formatter.stringFromDistance($0 as CLLocationDistance)
		}
	}

	// MARK: - Initialization

	func setUp() {
		formatter.unitStyle = MKDistanceFormatterUnitStyle.Abbreviated

		formattedMarks = formattedMarksFromMarks(marks)
		let style = markAttributes[NSParagraphStyleAttributeName] as! NSMutableParagraphStyle
		style.alignment = NSTextAlignment.Center;

		animator = UIDynamicAnimator(referenceView: self)
		animator.delegate = self
		addGestureRecognizer(PanGestureRecognizer(target: self, action: #selector(DistancePicker.pan(_:))))
	}
	override public init(frame: CGRect) {
		super.init(frame: frame)
		setUp()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUp()
	}
	
	// MARK: - Event Handling
	
	func decelerationBehaviorWithVelocity(velocity: CGPoint) -> UIDynamicItemBehavior {
		let inverseVelocity = CGPoint(x: velocity.x, y: 0)
		let decelerationBehavior = UIDynamicItemBehavior(items: [dynamicItem])

		dynamicItem.center = CGPoint(x: offset, y: 0)

		decelerationBehavior.addLinearVelocity(inverseVelocity, forItem: dynamicItem);
		decelerationBehavior.resistance = 4.0
		decelerationBehavior.action = {
			self.offset = self.dynamicItem.center.x
		}
		
		return decelerationBehavior
	}

	func pan(recognizer: UIPanGestureRecognizer) {
		let velocity = recognizer.velocityInView(self)
		
		if recognizer.state == UIGestureRecognizerState.Began {
			animator.removeAllBehaviors()
		}
		else if recognizer.state == UIGestureRecognizerState.Changed {
			assert(animator.behaviors.isEmpty)

			offset += recognizer.translationInView(self).x
			recognizer.setTranslation(CGPointZero, inView: self)
		}
		else if recognizer.state == UIGestureRecognizerState.Ended {
			assert(animator.behaviors.isEmpty)

			animator.addBehavior(decelerationBehaviorWithVelocity(velocity))
		}
	}

	// MARK: Drawing

	override public func drawRect(rect: CGRect) {
		var position = CGPoint(x: offset, y: 0)

		for mark in formattedMarks {
			let tickMarkEndPoint = CGPoint(x: position.x, y: position.y + 7)
			let markValueRect = markValueRectForPosition(position)
			var attributes = markAttributes

			self.drawLineFrom(position,
			              to: tickMarkEndPoint,
		           withColor: markColor)
			
			if (selectedFormattedMark == mark) {
				let font = attributes[NSFontAttributeName] as! UIFont
				let selectedFont = UIFont(name: "Avenir-Heavy", size: font.pointSize)!

				attributes[NSForegroundColorAttributeName] = tintColor
				attributes[NSFontAttributeName] = selectedFont
				
				// To compute a corrected center:
				//markValueRect.origin.y -= (selectedFont.capHeight - font.capHeight) / 2
			}
			
			mark.drawInRect(markValueRect, withAttributes: attributes)

			if formattedMarks.last != mark {
				drawMarkIncrementsFromPosition(position)
			}
			
			position.x += markSpacing
		}
		
		drawLineFrom(CGPoint(x: bounds.width * 0.5, y: position.y),
			     to: CGPoint(x: bounds.width * 0.5, y: position.y + 10),
		  withColor: tintColor)
	}
	
	func drawMarkIncrementsFromPosition(startPosition: CGPoint) {
		let incrementSpacing = markSpacing / CGFloat(numberOfIncrementsBetweenMarks)
		var position = CGPoint(x: startPosition.x + incrementSpacing, y: startPosition.y)

		for _ in 1..<numberOfIncrementsBetweenMarks {
			let tickMarkEndPoint = CGPoint(x: position.x, y: position.y + 4)

			drawLineFrom(position,
			         to: tickMarkEndPoint,
		      withColor: incrementColor)

			position.x += incrementSpacing
		}
	}
	
	func markValueRectForPosition(position: CGPoint) -> CGRect {
		let maxWidth = markSpacing
		let maxHeight = CGFloat.max
		let yOffset: CGFloat = 16// was using 12 previously

		return CGRect(x: position.x - maxWidth * 0.5,
		              y: position.y + yOffset,
		          width: maxWidth,
		         height: maxHeight)
	}
	
	func drawLineFrom(startPoint: CGPoint, to endPoint: CGPoint, withColor color: UIColor) {
		let line = UIBezierPath();
		
		line.moveToPoint(startPoint);
		line.addLineToPoint(endPoint);
		color.setStroke()
		line.stroke()
	}
	
	// MARK: Dynamic Animator
	
	public func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
		precondition(NSThread.isMainThread())
		
		// Prevent the deceleration behavior to be called on rotation (overwriting 
		// the offset set with frame.didSet)
		animator.removeAllBehaviors()

		// The picker can become invisible between the moment the user starts to 
		// swipe accross it and when the deceleration ends. This occurs when 
		// the user rotates the screen or navigates to the previous/next screen.
		let hasBecomeInvisible = window == nil

		if action == nil || target == nil || hasBecomeInvisible {
			return
		}
		sendAction(action!,
		       to: target!,
		 forEvent: (gestureRecognizers![0] as! PanGestureRecognizer).endEvent)
	}
}


class PanGestureRecognizer : UIPanGestureRecognizer {
	
	var endEvent: UIEvent?

	override func touchesBegan(touches: Set<NSObject>!, withEvent event: UIEvent!) {
		super.touchesBegan(touches as Set<NSObject>, withEvent: event)
		endEvent = nil
	}

	override func touchesEnded(touches: Set<NSObject>!, withEvent event: UIEvent!) {
		super.touchesEnded(touches as Set<NSObject>, withEvent: event)
		endEvent = event
	}
}


private class DynamicItem : NSObject, UIDynamicItem {

	@objc var center = CGPoint.zero
	// Bounds must be initialized with a size bigger than zero to prevent an exception
	@objc var bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
	@objc var transform = CGAffineTransform()
}
