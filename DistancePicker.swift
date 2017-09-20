/**
	Copyright (C) 2014 Quentin Mathe
 
	Date:  November 2014
	License:  MIT
 */

import Foundation
import UIKit
import MapKit


open class DistancePicker : UIControl, UIDynamicAnimatorDelegate {
	
	// MARK: - Cached State

	open var formatter = MKDistanceFormatter()
	
	// MARK: - Target/Action State
	
	open weak var target: AnyObject?
	open var action: Selector?

	// MARK: - Content State

	open var marks: [Double] = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 5000, 10000, 20000, 30000, 50000, 100000, 200000, .greatestFiniteMagnitude] {
		didSet {
			formattedMarks = formattedMarksFromMarks(marks)
		}
	}
	open var formattedMarks: [String]!
	open var usesMetricSystem: Bool = true {
		didSet {
			formatter.units = usesMetricSystem ? .metric : .imperial
			formattedMarks = formattedMarksFromMarks(marks)
		}
	}

	// MARK: - Appearance State

	// Due to a bug in Swift 2.2, we have to call init explicity.
	//
	// Was using systemFontOfSize(11) previously.
	open var markAttributes = [NSFontAttributeName: UIFont.init(name: "Avenir-Medium", size: 13)!,
	                   NSParagraphStyleAttributeName: NSMutableParagraphStyle(),
	                  NSForegroundColorAttributeName: UIColor.gray.withAlphaComponent(0.8)]
	open var markSpacing = CGFloat(50)
	open var markColor = UIColor.lightGray
	open var numberOfIncrementsBetweenMarks = 5
	open var incrementSpacing: CGFloat {
		return markSpacing / CGFloat(numberOfIncrementsBetweenMarks)
	}
	open var incrementColor = UIColor.lightGray.withAlphaComponent(0.5)
	open var markLineLength: CGFloat {
		return markSpacing * CGFloat(marks.count - 1)
	}
	
	// MARK: - Selection State

	// The selected position on the mark line that starts with zero and ends 
	// with -markLineLength.
	// This position usually falls between two mark positions. We can extract
	// the lower and upper marks with floor(), ceil() or round() to round it
	// towards the closest mark.
	open var selectedPosition: CGFloat {
		return bounds.width * 0.5 - offset
	}
	open var selectedMarkIndex: Int  {
		return previousMarkIndex
	}
	// The index of the mark before the selected point
	fileprivate var previousMarkIndex: Int {
		let markIndex = Int(floor(selectedPosition / markSpacing))
		return markIndex > (marks.count - 1) ? marks.count - 1 : markIndex
	}
	// The index of the mark after the selected point
	fileprivate var nextMarkIndex: Int {
		let markIndex = Int(ceil(selectedPosition / markSpacing))
		return markIndex > (marks.count - 1) ? marks.count - 1 : markIndex
	}
	open var selectedMark: Double {
		//print("Selected mark index \(selectedMarkIndex)")
		return marks[selectedMarkIndex]
	}
	open var selectedFormattedMark: String {
		return formattedMarks[selectedMarkIndex]
	}
	open var selectedIncrementIndex: Int {
		let selectedMarkPosition = CGFloat(selectedMarkIndex) * markSpacing
		let positionFromMark = selectedPosition - selectedMarkPosition
		let incrementIndex = Int(round(positionFromMark / incrementSpacing))

		return incrementIndex > (numberOfIncrementsBetweenMarks - 1) ? numberOfIncrementsBetweenMarks - 1 : incrementIndex
	}
	open var selectedIncrement: Double {
		// When the next mark is the last one (infinite), we use a 1000 km as
		// our last mark value, to compute the increment on a range between
		// 200 km and 1000 km.
		let maxMarkForIncrement = Double(1000000)
		let nextMark = marks[nextMarkIndex] == .greatestFiniteMagnitude ? maxMarkForIncrement : marks[nextMarkIndex]
		let previousMark = marks[previousMarkIndex] == .greatestFiniteMagnitude ? maxMarkForIncrement : marks[previousMarkIndex]
		let incrementTotal = nextMark - previousMark
		//print("Increment total \(incrementTotal)")
		assert(incrementTotal >= 0 && incrementTotal <= maxMarkForIncrement)
		let incrementValue = incrementTotal != 0 ? incrementTotal / Double(numberOfIncrementsBetweenMarks) : Double(0)
		
		return Double(selectedIncrementIndex) * incrementValue
	}
	open var selectedValue: Double {
		//print("Selected mark \(selectedMark) increment \(selectedIncrement)")
		return selectedMark == .greatestFiniteMagnitude ? selectedMark : selectedMark + selectedIncrement
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
	open var offset: CGFloat = CGFloat(0) {
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
	open var minOffset: CGFloat {
		return -(markLineLength - (bounds.size.width * 0.5))
	}
	// The maximum offset corresponds to the zero mark, since we move the
	// picker to the right (the offset grows towards positive numbers).
	open var maxOffset: CGFloat {
		return bounds.size.width * 0.5
	}
	fileprivate var normalizedBounds: CGRect {
		var normalizedBounds = bounds
		normalizedBounds.size.width = 1000
		return normalizedBounds
	}
	// An offset that can be saved and reloaded indepently of the distance 
	// picker bounds (e.g. when the screen is rotated or bigger/smaller)
	open var normalizedOffset: CGFloat {
		get {
			return convertOffset(offset, fromBounds: bounds, toBounds: normalizedBounds)
		}
		set {
			offset = convertOffset(newValue, fromBounds: normalizedBounds, toBounds: bounds)
		}
	}
	// Adjust the offset on resizing (this means screen rotation is supported)
	override open var frame: CGRect {
		didSet {
			offset = convertOffset(offset, fromBounds: oldValue, toBounds: frame)
    	}
	}
	
	open func convertOffset(_ offset: CGFloat,
	               fromBounds oldBounds: CGRect,
	                 toBounds newBounds: CGRect) -> CGFloat {
		return offset + (newBounds.size.width - oldBounds.size.width) / 2
	}

	// MARK: - Animation State

	fileprivate var dynamicItem = DynamicItem()
	open var animator: UIDynamicAnimator!

	open func formattedMarksFromMarks(_ marks: [Double]) -> [String] {
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
			let miles = $0 == .greatestFiniteMagnitude ? .greatestFiniteMagnitude : $0 / 1000

			return metersFromMiles(miles)
		}

		return meterMarks.map {
			if $0 == .greatestFiniteMagnitude {
				return "∞"
			}
			
			// Distance argument must be in meters
			return self.formatter.string(fromDistance: $0 as CLLocationDistance)
		}
	}

	// MARK: - Initialization

	fileprivate func setUp() {
		usesMetricSystem = shouldUseMetricSystem()
		formatter.unitStyle = MKDistanceFormatterUnitStyle.abbreviated

		formattedMarks = formattedMarksFromMarks(marks)
		let style = markAttributes[NSParagraphStyleAttributeName] as! NSMutableParagraphStyle
		style.alignment = NSTextAlignment.center;

		animator = UIDynamicAnimator(referenceView: self)
		animator.delegate = self
		addGestureRecognizer(PanGestureRecognizer(target: self, action: #selector(DistancePicker.pan(_:))))
	}

	override public init(frame: CGRect) {
		super.init(frame: frame)
		setUp()
		backgroundColor = UIColor.white
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUp()
	}
	
	// MARK: - Event Handling
	
	open func decelerationBehaviorWithVelocity(_ velocity: CGPoint) -> UIDynamicItemBehavior {
		let inverseVelocity = CGPoint(x: velocity.x, y: 0)
		let decelerationBehavior = UIDynamicItemBehavior(items: [dynamicItem])

		dynamicItem.center = CGPoint(x: offset, y: 0)

		decelerationBehavior.addLinearVelocity(inverseVelocity, for: dynamicItem);
		decelerationBehavior.resistance = 4.0
		decelerationBehavior.action = {
			self.offset = self.dynamicItem.center.x
		}
		
		return decelerationBehavior
	}

	open func pan(_ recognizer: UIPanGestureRecognizer) {
		let velocity = recognizer.velocity(in: self)
		
		if recognizer.state == UIGestureRecognizerState.began {
			animator.removeAllBehaviors()
		}
		else if recognizer.state == UIGestureRecognizerState.changed {
			assert(animator.behaviors.isEmpty)

			offset += recognizer.translation(in: self).x
			recognizer.setTranslation(CGPoint.zero, in: self)
		}
		else if recognizer.state == UIGestureRecognizerState.ended {
			assert(animator.behaviors.isEmpty)

			animator.addBehavior(decelerationBehaviorWithVelocity(velocity))
		}
	}

	// MARK: Drawing

	override open func draw(_ rect: CGRect) {
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
			
			mark.draw(in: markValueRect, withAttributes: attributes)

			if formattedMarks.last != mark {
				drawMarkIncrementsFromPosition(position)
			}
			
			position.x += markSpacing
		}
		
		drawLineFrom(CGPoint(x: bounds.width * 0.5, y: position.y),
			     to: CGPoint(x: bounds.width * 0.5, y: position.y + 10),
		  withColor: tintColor)
	}
	
	open func drawMarkIncrementsFromPosition(_ startPosition: CGPoint) {
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
	
	fileprivate func markValueRectForPosition(_ position: CGPoint) -> CGRect {
		let maxWidth = markSpacing
		let maxHeight = CGFloat.greatestFiniteMagnitude
		// Was using 12 previously
		let yOffset: CGFloat = 16

		return CGRect(x: position.x - maxWidth * 0.5,
		              y: position.y + yOffset,
		          width: maxWidth,
		         height: maxHeight)
	}
	
	open func drawLineFrom(_ startPoint: CGPoint, to endPoint: CGPoint, withColor color: UIColor) {
		let line = UIBezierPath();
		
		line.move(to: startPoint);
		line.addLine(to: endPoint);
		color.setStroke()
		line.stroke()
	}
	
	// MARK: Dynamic Animator
	
	open func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
		precondition(Thread.isMainThread)
		
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
		 for: (gestureRecognizers![0] as! PanGestureRecognizer).endEvent)
	}
}


// MARK: Unit Utilities

public func shouldUseMetricSystem() -> Bool {
	let usesMetric = ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem)! as AnyObject).boolValue as Bool
	let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
	
	return usesMetric && countryCode != "GB"
}

public func metersFromMiles(_ miles: Double) -> Double {
	if miles == .greatestFiniteMagnitude {
		return .greatestFiniteMagnitude
	}
	return miles * 1609.344
}

public func milesFromMeters(_ meters: Double) -> Double {
	if meters == .greatestFiniteMagnitude {
		return .greatestFiniteMagnitude
	}
	return meters * 0.000621371192
}


// MARK: Private Classes

private class PanGestureRecognizer : UIPanGestureRecognizer {
	
	var endEvent: UIEvent?

	func touchesBegan(_ touches: Set<NSObject>!, with event: UIEvent!) {
		super.touchesBegan(touches as Set<NSObject>, with: event)
		endEvent = nil
	}

	func touchesEnded(_ touches: Set<NSObject>!, with event: UIEvent!) {
		super.touchesEnded(touches as Set<NSObject>, with: event)
		endEvent = event
	}
}


private class DynamicItem : NSObject, UIDynamicItem {

	@objc var center = CGPoint.zero
	// Bounds must be initialized with a size bigger than zero to prevent an exception
	@objc var bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
	@objc var transform = CGAffineTransform()
}
