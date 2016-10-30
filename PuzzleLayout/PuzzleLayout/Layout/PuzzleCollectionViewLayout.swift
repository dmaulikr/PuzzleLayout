//
//  PuzzleCollectionViewLayout.swift
//  CollectionTest
//
//  Created by Yossi houzz on 23/09/2016.
//  Copyright © 2016 Yossi. All rights reserved.
//

import UIKit

//MARK: - CollectionViewDataSourcePuzzleLayout
protocol CollectionViewDataSourcePuzzleLayout : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: PuzzleCollectionViewLayout, layoutForSectionAtIndex index: Int) -> PuzzlePieceSectionLayout
}

//MARK: - PuzzleCollectionViewLayout
final public class PuzzleCollectionViewLayout: UICollectionViewLayout {
    
    fileprivate var sectionsLayoutInfo: [PuzzlePieceSectionLayout] = []
    
    //MARK: - Init
    override public init() {
        super.init()
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        register(ColoredDecorationView.self, forDecorationViewOfKind: PuzzleCollectionElementKindSeparatorLine)
        register(ColoredDecorationView.self, forDecorationViewOfKind: PuzzleCollectionElementKindSectionTopGutter)
        register(ColoredDecorationView.self, forDecorationViewOfKind: PuzzleCollectionElementKindSectionBottomGutter)
    }
    
    //MARK: - Public
    public func reloadSectionsLayout() {
        let context = PuzzleCollectionViewLayoutInvalidationContext(invalidateSectionsLayout: true)
        invalidateLayout(with: context)
    }
    
    func dequeueSectionLayout(for identifier: String) -> PuzzlePieceSectionLayout? {
        return sectionsLayoutInfo.filter ({ (layout: PuzzlePieceSectionLayout) -> Bool in
            if let layoutIdentifier = layout.identifier {
                return layoutIdentifier == identifier
            }
            else {
                return false
            }
        }).first
    }
    
    public var separatorLineColor: UIColor? {
        didSet {
            let ctx = PuzzleCollectionViewLayoutInvalidationContext()
            for (sectionIndex, sectionInfo) in sectionsLayoutInfo.enumerated() {
                switch sectionInfo.separatorLineStyle {
                case .allButLastItem:
                    if sectionInfo.numberOfItemsInSection > 0 {
                        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSeparatorLine, at: IndexPath.indexPaths(for: sectionIndex, itemsRange: 0..<(sectionInfo.numberOfItemsInSection-1)))
                    }
                case .all:
                    if sectionInfo.numberOfItemsInSection != 0 {
                        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSeparatorLine, at: IndexPath.indexPaths(for: sectionIndex, itemsRange: 0..<sectionInfo.numberOfItemsInSection))
                    }
                default: break
                }
            }
            invalidateLayout(with: ctx)
        }
    }
    
    //MARK: - Override
    override public class var layoutAttributesClass : AnyClass {
        return PuzzleCollectionViewLayoutAttributes.self
    }
    
    override public class var invalidationContextClass : AnyClass {
        return PuzzleCollectionViewLayoutInvalidationContext.self
    }
    
    override public var collectionViewContentSize: CGSize {
        var height: CGFloat = 0
        for layoutInfo in sectionsLayoutInfo {
            height += layoutInfo.heightOfSection
        }
        
        return CGSize(width: collectionView!.bounds.width, height: height)
    }
    
    override public func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        guard let ctx = (context as? PuzzleCollectionViewLayoutInvalidationContext) else {
            assert(false, "Invalidation context should be of type 'PuzzleCollectionViewLayoutInvalidationContext'")
            return
        }
        
        if ctx.invalidateEverything || ctx.invalidateDataSourceCounts || ctx.invalidateSectionsLayout {
            invalidateEverything = invalidateEverything || ctx.invalidateEverything
            invalidateDataSourceCounts = invalidateDataSourceCounts || ctx.invalidateDataSourceCounts
            invalidateSectionsLayout = invalidateSectionsLayout || ctx.invalidateSectionsLayout
            for sectionLayout in sectionsLayoutInfo {
                sectionLayout.invalidate(willReloadData: ctx.invalidateEverything, willUpdateDataSourceCounts: ctx.invalidateDataSourceCounts, resetLayout: ctx.invalidateSectionsLayout, info: nil)
            }
        }
        else {
            let invalidationInfo = ctx.invalidationInfo
            if let layout = ctx.invalidateSectionLayoutData {
                layout.invalidate(willReloadData: false, willUpdateDataSourceCounts: false, resetLayout: false, info: invalidationInfo[layout.sectionIndex!])
            }
            else {
                
                let updatedSpecificView = !(
                    (ctx.invalidatedItemIndexPaths?.isEmpty ?? true)
                        || (ctx.invalidatedSupplementaryIndexPaths?.isEmpty ?? true)
                        || (ctx.invalidatedDecorationIndexPaths?.isEmpty ?? true)
                )
                
                if let invalidatedItemIndexPaths = ctx.invalidatedItemIndexPaths {
                    for indexPath in invalidatedItemIndexPaths {
                        sectionsLayoutInfo[indexPath.item].invalidateItem(at: indexPath)
                    }
                }
                
                if let invalidatedSupplementaryIndexPaths = ctx.invalidatedSupplementaryIndexPaths {
                    for (elementKind, indexPaths) in invalidatedSupplementaryIndexPaths {
                        for indexPath in indexPaths {
                            sectionsLayoutInfo[indexPath.item].invalidateSupplementaryView(ofKind: elementKind, at: indexPath)
                        }
                    }
                }
                
                if let invalidatedDecorationIndexPaths = ctx.invalidatedDecorationIndexPaths {
                    for (elementKind, indexPaths) in invalidatedDecorationIndexPaths {
                        for indexPath in indexPaths {
                            sectionsLayoutInfo[indexPath.item].invalidateDecorationView(ofKind: elementKind, at: indexPath)
                        }
                    }
                }
                
                if !updatedSpecificView {
                    for (index,info) in invalidationInfo {
                        sectionsLayoutInfo[index].invalidate(willReloadData: false, willUpdateDataSourceCounts: false, resetLayout: false, info: info)
                    }
                }
            }
        }
        
        super.invalidateLayout(with: context)
    }
    
    private var invalidateEverything: Bool = false
    private var invalidateDataSourceCounts: Bool = false
    private var invalidateSectionsLayout: Bool = false
    override public func prepare() {
        if invalidateEverything || invalidateDataSourceCounts || invalidateSectionsLayout {
            prepareSectionsLayout()
        }
        
        let didReloadData = invalidateEverything
        let didUpdateDataSourceCounts = invalidateDataSourceCounts
        let didResetLayout =  invalidateSectionsLayout
        
        invalidateEverything = false
        invalidateDataSourceCounts = false
        invalidateSectionsLayout = false
        
        for sectionLayout in sectionsLayoutInfo {
            sectionLayout.prepare(didReloadData: didReloadData, didUpdateDataSourceCounts: didUpdateDataSourceCounts, didResetLayout: didResetLayout)
        }
        
        super.prepare()
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var attributes: [PuzzleCollectionViewLayoutAttributes] = []
        var lastY: CGFloat = 0
        
        let width = collectionView!.bounds.width
        
        //Iterate over each section layout
        for sectionIndex in 0 ..< sectionsLayoutInfo.count {
            let layout = sectionsLayoutInfo[sectionIndex]
            assert(sectionIndex == layout.sectionIndex!, "Something went wrong. This shouldn't happen")
            
            let sectionHeight = layout.heightOfSection
            let sectionFrame = CGRect(x: 0, y: lastY, width: width, height: sectionHeight)
            
            //Check if section intersects & get its elements layout attributes
            let intersection = rect.intersection(sectionFrame)
            
            if intersection.height > 0 { //Section intersects with rect
                let rectInSectionBounds = CGRect(origin: CGPoint(x: sectionFrame.minX, y: sectionFrame.minY - lastY), size: sectionFrame.size)
                
                //Ask for layout attributes depend the required data info required
                
                //Get items without specifying any information about section origin. Then update for each layout attributes its origin Y
                var items: [PuzzleCollectionViewLayoutAttributes]
                
                //"layoutAttributesForElements(atSection:in:) is required when 'dataRequiredForLayoutAttributes' == .none"
                items = layout.layoutAttributesForElements(in: rectInSectionBounds, sectionIndex: sectionIndex)
                if items.isEmpty == false {
                    //Update for each layout attributes its origin Y
                    var sectionHeader: PuzzleCollectionViewLayoutAttributes?
                    var sectionFooter: PuzzleCollectionViewLayoutAttributes?
                    
                    for item in items {
                        item.center.y += lastY
                        attributes.append(item)
                        
                        if item.representedElementCategory == .supplementaryView {
                            //Pin header/footer if needed
                            switch item.representedElementKind! {
                            case PuzzleCollectionElementKindSectionHeader:
                                if layout.shouldPinHeaderSupplementaryView() {
                                    item.zIndex = PuzzleCollectionHeaderFooterZIndex
                                    sectionHeader = item
                                }
                                else {
                                    item.zIndex = 0
                                }
                            case PuzzleCollectionElementKindSectionFooter:
                                if layout.shouldPinFooterSupplementaryView() {
                                    item.zIndex = PuzzleCollectionHeaderFooterZIndex
                                    sectionFooter = item
                                }
                                else {
                                    item.zIndex = 0
                                }
                            default: break
                            }
                        }
                        
                        //Add separator lines if needed
                        if (
                            item.representedElementCategory != .cell
                            || layout.separatorLineStyle == .none
                            || (layout.separatorLineStyle == .allButLastItem
                                && item.indexPath.item + 1 == layout.numberOfItemsInSection)
                            ) {
                            //No separator line
                        }
                        else {
                            let separatorFrame = CGRect(x: item.frame.minX + layout.separatorLineInsets.left, y: item.frame.maxY - 0.5, width: item.bounds.width - (layout.separatorLineInsets.left + layout.separatorLineInsets.right), height: 0.5)
                            if rect.intersects(separatorFrame) {
                                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: PuzzleCollectionElementKindSeparatorLine, with: item.indexPath)
                                separatorLine.frame = separatorFrame
                                separatorLine.zIndex = PuzzleCollectionColoredViewZIndex
                                if let color = layout.separatorLineColor ?? separatorLineColor {
                                    separatorLine.info = [PuzzleCollectionColoredViewColorKey : color]
                                }
                                attributes.append(separatorLine)
                            }
                        }
                    }
                    
                    if sectionHeader != nil || sectionFooter != nil {
                        let shouldPinHeader = layout.shouldPinHeaderSupplementaryView()
                        let shouldPinFooter = layout.shouldPinFooterSupplementaryView()
                        
                        let contentOffsetY = collectionView!.bounds.minY + collectionView!.contentInset.top
                        
                        if shouldPinHeader && sectionHeader == nil {
                            if let header = layout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionHeader, at: IndexPath(item: 0, section: sectionIndex)) {
                                header.center.y += lastY
                                header.zIndex = PuzzleCollectionHeaderFooterZIndex
                                attributes.append(header)
                                sectionHeader = header
                            }
                        }
                        
                        if shouldPinFooter && sectionFooter == nil {
                            if let footer = layout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionFooter, at: IndexPath(item: 0, section: sectionIndex)) {
                                footer.center.y += lastY
                                footer.zIndex = PuzzleCollectionHeaderFooterZIndex
                                attributes.append(footer)
                                sectionFooter = footer
                            }
                        }
                        
                        if let header = sectionHeader {
                            let y = sectionHeader!.frame.minY
                            if sectionFrame.minY < contentOffsetY {
                                let maxY = (sectionFooter?.frame.minY ?? sectionFrame.maxY) - header.frame.height
                                sectionHeader!.frame.origin.y = min(contentOffsetY, maxY)
                            }
                            
                            header.isPinned = (y != sectionHeader!.frame.minY)
                        }
                        
                        if let footer = sectionFooter {
                            let contentY = (sectionHeader?.frame.maxY ?? contentOffsetY)
                            let y = sectionFooter!.frame.minY
                            if sectionFrame.maxY > contentY {
                                let minY = max(collectionView!.bounds.maxY - footer.frame.height, sectionFrame.minY)
                                sectionFooter!.frame.origin.y = min(sectionFrame.maxY - footer.frame.height, minY)
                            }
                            footer.isPinned = (y != sectionFooter!.frame.minY)
                        }
                    }
                }
            }
            else if sectionFrame.minY >= rect.maxY { //Section isn't intersecting with rect. Remaining sections can't intersect with rect too, so stop looping
                break
            }
//            else { //Section isn't intersecting with rect. But, next sections might intersect with rect, so don't stop looping
//            }
            
            // ----- End check if section intersects & get its elements layout attributes
            
            
            //Update before next iteration
            lastY += sectionHeight
            // ----- Update before next iteration
        }
        
        return attributes
    }
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layout = sectionsLayoutInfo[indexPath.section]
        
        if let item = layout.layoutAttributesForItem(at: indexPath) {
            let originY = self.originY(forSectionAt: indexPath.section)
            item.center.y += originY
            return item
        }
        else { return nil }
    }
    
    override public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layout = sectionsLayoutInfo[indexPath.section]
        
        if let item = layout.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) {
            let originY = self.originY(forSectionAt: indexPath.section)
            item.center.y += originY
            item.zIndex = 0
            
            switch item.representedElementKind! {
            case PuzzleCollectionElementKindSectionHeader where layout.shouldPinHeaderSupplementaryView():
                let y = item.frame.minY
                
                item.zIndex = PuzzleCollectionHeaderFooterZIndex
                let contentOffsetY = collectionView!.bounds.minY + collectionView!.contentInset.top
                let sectionMaxY = originY + layout.heightOfSection
                if originY < contentOffsetY {
                    let footerToPin = (layout.shouldPinFooterSupplementaryView() ? layout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionFooter, at: indexPath) : nil)
                    footerToPin?.center.y += originY
                    let maxY = (footerToPin?.frame.minY ?? sectionMaxY) - item.frame.height
                    item.frame.origin.y = min(contentOffsetY, maxY)
                }
                
                item.isPinned = (y != item.frame.minY)
            case PuzzleCollectionElementKindSectionFooter where layout.shouldPinFooterSupplementaryView():
                let y = item.frame.minY
                
                item.zIndex = PuzzleCollectionHeaderFooterZIndex
                let headerToPin = (layout.shouldPinHeaderSupplementaryView() ? layout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionHeader, at: indexPath) : nil)
                let contentOffsetY = collectionView!.bounds.minY + collectionView!.contentInset.top
                let contentY = (headerToPin?.frame.maxY ?? contentOffsetY)
                let sectionMaxY = originY + layout.heightOfSection
                if sectionMaxY > contentY {
                    item.frame.origin.y = min(sectionMaxY - item.frame.height, collectionView!.bounds.maxY - item.frame.height)
                }
                
                item.isPinned = (y != item.frame.minY)
            default: break
            }
            
            return item
        }
        else { return nil }
    }
    
    override public func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == PuzzleCollectionElementKindSeparatorLine {
            let layout = sectionsLayoutInfo[indexPath.section]
            if layout.separatorLineStyle == .none || (layout.separatorLineStyle == .allButLastItem && indexPath.item + 1 == layout.numberOfItemsInSection) {
                //There's no need in line view, but returning nil cause a crash.
                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                separatorLine.isHidden = true
                separatorLine.frame.size = .zero
                return separatorLine
            }
            else if let item = layoutAttributesForItem(at: indexPath) {
                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                separatorLine.frame = CGRect(x: item.frame.minX + layout.separatorLineInsets.left, y: item.frame.maxY - 0.5, width: item.bounds.width - (layout.separatorLineInsets.left + layout.separatorLineInsets.right), height: 0.5)
                separatorLine.zIndex = PuzzleCollectionColoredViewZIndex
                if let color = layout.separatorLineColor ?? separatorLineColor {
                    separatorLine.info = [PuzzleCollectionColoredViewColorKey : color]
                }
                return separatorLine
            }
            else {
                //There's no need in line view, but returning nil cause a crash.
                let separatorLine = PuzzleCollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
                separatorLine.isHidden = true
                separatorLine.frame.size = .zero
                return separatorLine
            }
        }
        else {
            let layout = sectionsLayoutInfo[indexPath.section]
            
            if let item = layout.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath) {
                let originY = self.originY(forSectionAt: indexPath.section)
                item.center.y += originY
                return item
            }
            else { return nil }
        }
    }
    
    private var invalidationInfoForBoundsChange: InvalidationInfoForBoundsChange?
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        //Since this is a vertical layout, changes in origin y or size width should be relavant for us. Origin x should never get changes, since collectionView.contentSize.widht == collectionView.widht. In addition. Changing size height, should insert or remove cells, depend the height change.
        
        let oldBounds = collectionView!.bounds
        let oldWidth = oldBounds.width
        let newWidth = newBounds.width
        if newWidth != oldWidth {
            return true
        }
        
        if newBounds.minY != oldBounds.minY {
            //Check if there's a section layout which require invalidation for bounds change
            
            var lastY: CGFloat = 0
            var invalidationInfo = InvalidationInfoForBoundsChange()
            for sectionLayout in sectionsLayoutInfo {
                let sectionHeight = sectionLayout.heightOfSection
                let maxSectionY = lastY + sectionHeight
                if maxSectionY < newBounds.minY && maxSectionY < oldBounds.minY {
                    lastY = maxSectionY
                    continue
                }
                else if lastY >= newBounds.maxY && lastY >= oldBounds.maxY {
                    //Section isn't intersecting with rect. Remaining sections can't intersect with rect too, so stop looping
                    break
                }
                
                let sectionIndex = sectionLayout.sectionIndex!
                let headerToPin: PuzzleCollectionViewLayoutAttributes?
                if sectionLayout.shouldPinHeaderSupplementaryView() {
                    headerToPin = sectionLayout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionHeader, at: IndexPath(item: 0, section: sectionIndex))
                }
                else { headerToPin = nil }
                
                let footerToPin: PuzzleCollectionViewLayoutAttributes?
                if sectionLayout.shouldPinFooterSupplementaryView() {
                    footerToPin = sectionLayout.layoutAttributesForSupplementaryView(ofKind: PuzzleCollectionElementKindSectionFooter, at: IndexPath(item: 0, section: sectionIndex))
                }
                else { footerToPin = nil }
                
                guard headerToPin != nil || footerToPin != nil else {
                    lastY += sectionHeight
                    continue
                }
                
                let sectionFrame = CGRect(x: 0, y: lastY, width: newWidth, height: sectionHeight)
                
                //Check if section intersects & get its elements layout attributes
                let oldFrameIntersection = sectionFrame.intersection(oldBounds)
                let newFrameIntersection = sectionFrame.intersection(newBounds)
                
                if oldFrameIntersection.height > 0 || newFrameIntersection.height > 0 {
                    
                    if let headerToPin = headerToPin {
                        invalidationInfo.headersIndexPathToPin.append(headerToPin.indexPath)
                    }
                    
                    if let footerToPin = footerToPin {
                        invalidationInfo.footersIndexPathToPin.append(footerToPin.indexPath)
                    }
                }
//                else { //Section isn't intersecting with rect. But, next sections might intersect with rect, so don't stop looping
//                }
                
                lastY += sectionHeight
            }
            
            if invalidationInfo.headersIndexPathToPin.isEmpty && invalidationInfo.footersIndexPathToPin.isEmpty {
                invalidationInfoForBoundsChange = nil
                return super.shouldInvalidateLayout(forBoundsChange: newBounds)
            }
            else {
                invalidationInfoForBoundsChange = invalidationInfo
                return true
            }
        }
        else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
    }
    
    override public func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        
        let oldBounds = collectionView!.bounds
        let context = super.invalidationContext(forBoundsChange: newBounds) as! PuzzleCollectionViewLayoutInvalidationContext
        if newBounds.width != oldBounds.width {
            invalidateForWidthChange(byBoundsChange: newBounds, oldBounds: oldBounds, with: context)
        }
        else if let invalidationInfo = invalidationInfoForBoundsChange {
            if invalidationInfo.headersIndexPathToPin.isEmpty == false {
                context.invalidateSupplementaryElements(ofKind: PuzzleCollectionElementKindSectionHeader, at: invalidationInfo.headersIndexPathToPin)
            }
            
            if invalidationInfo.footersIndexPathToPin.isEmpty == false {
                context.invalidateSupplementaryElements(ofKind: PuzzleCollectionElementKindSectionFooter, at: invalidationInfo.footersIndexPathToPin)
            }
        }
        
        invalidationInfoForBoundsChange = nil
        return context
    }
    
    override public func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        if preferredAttributes.representedElementCategory == .decorationView {
            if preferredAttributes.representedElementKind == PuzzleCollectionElementKindSeparatorLine || preferredAttributes.representedElementKind == PuzzleCollectionElementKindSectionTopGutter || preferredAttributes.representedElementKind == PuzzleCollectionElementKindSectionBottomGutter {
                return false
            }
        }
        
        //Check if the section layout which generate 'originalAttributes' want to invalidate it for 'preferredAttributes'
        let layout = sectionsLayoutInfo[originalAttributes.indexPath.section]
        let invalidationType: InvalidationElementCategory
        switch preferredAttributes.representedElementCategory {
        case .cell:
            invalidationType = .cell(indexPath: originalAttributes.indexPath)
        case .supplementaryView:
            invalidationType = .supplementaryView(indexPath: originalAttributes.indexPath, elementKind: originalAttributes.representedElementKind!)
        case .decorationView:
            invalidationType = .decorationView(indexPath: originalAttributes.indexPath, elementKind: originalAttributes.representedElementKind!)
        }
        
        if layout.shouldInvalidate(for: invalidationType, forPreferredSize: &preferredAttributes.size, withOriginalSize: originalAttributes.size) {
            preferredAttributes.frame.origin.y = originalAttributes.frame.origin.y
            return true
        }
        else { return false }
    }
    
    override public func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let ctx = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes) as! PuzzleCollectionViewLayoutInvalidationContext
        #if DEBUGLog
            if ctx.contentOffsetAdjustment.y != 0 {
                DEBUGLog("Invalidate \(ctx.contentOffsetAdjustment) ; Preferred: \(preferredAttributes.size) ; Original: \(originalAttributes.size) ; Rect: \(collectionView!.bounds) ; \(originalAttributes.frame)")
            }
        #endif
        let sectionIndex = originalAttributes.indexPath.section
        let layout = sectionsLayoutInfo[sectionIndex]
        
        let invalidationType: InvalidationElementCategory
        switch preferredAttributes.representedElementCategory {
        case .cell:
            invalidationType = .cell(indexPath: originalAttributes.indexPath)
        case .supplementaryView:
            invalidationType = .supplementaryView(indexPath: originalAttributes.indexPath, elementKind: originalAttributes.representedElementKind!)
        case .decorationView:
            invalidationType = .decorationView(indexPath: originalAttributes.indexPath, elementKind: originalAttributes.representedElementKind!)
        }
        
        (preferredAttributes as? PuzzleCollectionViewLayoutAttributes)?.cachedSize = preferredAttributes.size
        ctx.invalidateSectionLayoutData = layout
        if let info = layout.invalidationInfo(for: invalidationType, forPreferredSize: preferredAttributes.size, withOriginalSize: originalAttributes.size) {
            ctx.setInvalidationInfo(info, forSectionAtIndex: sectionIndex)
        }
        return ctx
    }

    override public func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        var sectionUpdated: Set<Int> = []
        for layout in sectionsLayoutInfo {
            layout.willGenerateUpdatesCall()
        }
        
        for update in updateItems {
            guard let section = (update.indexPathAfterUpdate ?? update.indexPathBeforeUpdate)?.section else {
                continue
            }
            
            sectionUpdated.insert(section)
            switch update.updateAction {
            case .insert:
                let indexPath = update.indexPathAfterUpdate!
                sectionsLayoutInfo[section].didInsertItem(at: indexPath.item)
            case .delete:
                let indexPath = update.indexPathBeforeUpdate!
                sectionsLayoutInfo[section].didDeleteItem(at: indexPath.item)
            case .reload:
                let indexPath = update.indexPathAfterUpdate!
                sectionsLayoutInfo[section].didReloadItem(at: indexPath.item)
            case .move:
                let fromIndexPath = update.indexPathBeforeUpdate!
                let toIndexPath = update.indexPathAfterUpdate!
                if fromIndexPath.section == toIndexPath.section {
                    sectionsLayoutInfo[section].didMoveItem(fromIndex: fromIndexPath.item, toIndex: toIndexPath.item)
                }
                else {
                    sectionsLayoutInfo[fromIndexPath.section].didDeleteItem(at: fromIndexPath.item)
                    sectionsLayoutInfo[toIndexPath.section].didInsertItem(at: toIndexPath.item)
                    sectionUpdated.insert(update.indexPathBeforeUpdate!.section)
                }
            default: break
            }
        }
        
        for (idx,layout) in sectionsLayoutInfo.enumerated() {
            layout.didGenerateUpdatesCall(didHadUpdates: sectionUpdated.contains(idx))
        }
        
        super.prepare(forCollectionViewUpdates: updateItems)
    }
    
    //MARK: - Prepare sections layout
    private func prepareSectionsLayout() {
        guard let dataSource = collectionView!.dataSource as? CollectionViewDataSourcePuzzleLayout else {
            assert(false, "To use this layout, collection view data source must conform to 'CollectionViewDataSourcePuzzleLayout'")
            return
        }
        
        let numberOfSections = collectionView!.numberOfSections
        if numberOfSections > 0 {
            let oldLayouts = sectionsLayoutInfo
            var newLayouts: [PuzzlePieceSectionLayout] = [PuzzlePieceSectionLayout](repeating: PuzzlePieceSectionLayout(), count: numberOfSections)
            for layout in oldLayouts {
                layout.parentLayout = nil
            }
            
            for sectionIndex in 0 ..< numberOfSections {
                let numberOfItems = collectionView!.numberOfItems(inSection: sectionIndex)
                let layout = dataSource.collectionView(collectionView!, layout: self, layoutForSectionAtIndex: sectionIndex)
                //TODO: preapre with parentLayout=self & numberOfItems
                
                layout.parentLayout = self
                layout.numberOfItemsInSection = numberOfItems
                layout.sectionIndex = sectionIndex
                newLayouts[sectionIndex] = layout
            }
            
            sectionsLayoutInfo = newLayouts
            for layout in oldLayouts {
                //Layout wasn't used again when iterating the number of section just few lines above
                if layout.parentLayout == nil {
                    layout.sectionIndex = nil
                    layout.numberOfItemsInSection = 0
                    layout.tearDown()
                }
            }
        }
        else {
            let sectionsInfo = sectionsLayoutInfo
            sectionsLayoutInfo = []
            
            for layout in sectionsInfo {
                layout.parentLayout = nil
                layout.sectionIndex = nil
                layout.numberOfItemsInSection = 0
                layout.tearDown()
            }
        }
    }
    
    //MARK: - Private
    private func originY(forSectionAt index: Int) -> CGFloat {
        if index == 0 {
            return 0
        }
        else {
            var originY: CGFloat = 0
            for currentIndex in 0...(index-1) {
                let layout = sectionsLayoutInfo[currentIndex]
                originY += layout.heightOfSection
            }
            return originY
        }
    }
    
    private func invalidateForWidthChange(byBoundsChange newBounds: CGRect, oldBounds: CGRect, with context: PuzzleCollectionViewLayoutInvalidationContext) {
        context.invalidateForWidthChange = true
        var lastY: CGFloat = 0
        for sectionLayout in sectionsLayoutInfo {
            let sectionHeight = sectionLayout.heightOfSection
            
            let oldSectionFrame = CGRect(x: 0, y: lastY, width: oldBounds.width, height: sectionHeight)
            let newSectionFrame = CGRect(x: 0, y: lastY, width: newBounds.width, height: sectionHeight)
            
            //Check if section intersects & get its elements layout attributes
            let oldFrameIntersection = oldSectionFrame.intersection(oldBounds)
            let newFrameIntersection = newSectionFrame.intersection(newBounds)
            
            
            if oldFrameIntersection.height > 0 || newFrameIntersection.height > 0 {
                let oldSectionBounds = CGRect(origin: CGPoint(x: oldFrameIntersection.minX, y: oldFrameIntersection.minY - lastY), size: oldFrameIntersection.size)
                let newSectionBounds = CGRect(origin: CGPoint(x: newFrameIntersection.minX, y: newFrameIntersection.minY - lastY), size: newFrameIntersection.size)
                if let info = sectionLayout.invalidationInfo(forNewWidth: newSectionBounds.width, currentWidth: oldSectionBounds.width) {
                    let index = sectionLayout.sectionIndex!
                    context.setInvalidationInfo(info, forSectionAtIndex: index)
                }
            }
            else if oldFrameIntersection.minY >= oldBounds.maxY && newFrameIntersection.minY >= newBounds.maxY { //Section isn't intersecting with rect. Remaining sections can't intersect with rect too, so stop looping
                break
            }
//            else { //Section isn't intersecting with rect. But, next sections might intersect with rect, so don't stop looping
//            }
            
            lastY += sectionHeight
        }
    }
}

//MARK: - Private Util
fileprivate struct InvalidationInfoForBoundsChange {
    var headersIndexPathToPin: [IndexPath] = []
    var footersIndexPathToPin: [IndexPath] = []
}

fileprivate class ColoredDecorationView : UICollectionReusableView {
    fileprivate override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        let dict = (layoutAttributes as! PuzzleCollectionViewLayoutAttributes).info as? [AnyHashable:Any]
        backgroundColor = dict?[PuzzleCollectionColoredViewColorKey] as? UIColor ?? UIColor(red: 214/255, green: 214/255, blue: 214/255, alpha: 1)
    }
}

//MARK: - PuzzlePieceSectionLayout
extension PuzzlePieceSectionLayout {
    
    public func invalidationContextForSeparatorLines(for newStyle: PuzzlePieceSeparatorLineStyle, oldStyle: PuzzlePieceSeparatorLineStyle? = nil) -> PuzzleCollectionViewLayoutInvalidationContext? {
        let _oldStyle = oldStyle ?? newStyle
        if newStyle == _oldStyle && newStyle == .none {
            return nil
        }
        
        guard let sectionIndex = sectionIndex else {
            return nil
        }
        
        let layoutInfo = parentLayout!.sectionsLayoutInfo[sectionIndex]
        if layoutInfo.numberOfItemsInSection == 0 {
            return nil
        }
        else if layoutInfo.numberOfItemsInSection == 1 {
            if (_oldStyle == .none && newStyle == .allButLastItem) || (_oldStyle == .allButLastItem && newStyle == .none) {
                return nil
            }
        }
        
        let ctx = PuzzleCollectionViewLayoutInvalidationContext()
        ctx.invalidateSectionLayoutData = self
        let numberOfItems = (newStyle == .all || _oldStyle == .all) ? layoutInfo.numberOfItemsInSection : (layoutInfo.numberOfItemsInSection - 1)
        ctx.invalidateDecorationElements(ofKind: PuzzleCollectionElementKindSeparatorLine, at: IndexPath.indexPaths(for: sectionIndex, itemsRange: 0..<numberOfItems))
        return ctx
    }
}
