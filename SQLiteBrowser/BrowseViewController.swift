import UIKit
import SpreadsheetView

class BrowseViewController: UIViewController {
    
    fileprivate lazy var spreadsheetView: SpreadsheetView = {
        let spreadsheetView = SpreadsheetView(frame: self.view.bounds)
        spreadsheetView.dataSource = self
        spreadsheetView.delegate = self
        //        spreadsheetView.scrollView.delegate = self
        spreadsheetView.register(
            HeaderCell.self,
            forCellWithReuseIdentifier: String(describing: HeaderCell.self))
        spreadsheetView.register(
            TextCell.self,
            forCellWithReuseIdentifier: String(describing: TextCell.self))
        return spreadsheetView
    }()
    
    enum Sorting {
        case ascending, descending
        
        var symbol: String {
            return self == .ascending ? "▲" : "▼"
        }
    }
    
    var sortedColumn = (column: 0, sorting: Sorting.ascending)
    
    var start = 0
    var limit = 100
    var total = 0
    
    var fields = [TableField]()
    var records = DataResults()
    var schema = DataSchema()
    
    //    var isPullable = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = tableName
        view.backgroundColor = .white
        view.addSubview(spreadsheetView)
        
        getRecords()
        parseFields()
        spreadsheetView.reloadData()
        
        registerForPreviewing(with: self, sourceView: spreadsheetView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        spreadsheetView.flashScrollIndicators()
    }
    
    var tableName: String = ""
}


// MARK: - DB
extension BrowseViewController {
    
    func getRecords() {
        
        guard let results = Database.shared.browseAll(tableName) else { return }
        records = results
        start = 0
        total = Database.shared.recordCount(tableName)
    }
    
    func parseFields() {
        guard let fields = Database.shared.schema(tableName) else { return }
        schema.parseFields(fields)
        self.fields = schema.fields
    }
    
    func nextPage() {
        
        let edge = total - limit
        if start > edge { return }
        start += limit
        if start > total { start -= limit }
        
        if let results = Database.shared.browse(tableName, start:start, limit:limit) {
            records.append(contentsOf: results)
            spreadsheetView.reloadData()
            spreadsheetView.setNeedsDisplay()
        }
    }
}


// MARK: - SpreadsheetViewDataSource, SpreadsheetViewDelegate
extension BrowseViewController: SpreadsheetViewDataSource, SpreadsheetViewDelegate {
    
    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
        return fields.count
    }
    
    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
        return 1 + records.count
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
        switch fields.count {
        case 1:
            return view.bounds.width
        case 2:
            return view.bounds.width * 0.5
        case 3:
            return view.bounds.width * 0.33
        case 4:
            return view.bounds.width * 0.25
        default:
            let field = fields[column]
            var fieldName = field.name
            if field.primary {
                fieldName = fieldName + "🔑"
            }
            let text = fieldName + "\n" + fields[column].type.rawValue
            let width = text.toWidth(fontSize: 18)
            
            
            switch field.type {
            case .Text, .Varchar, .NVarchar, .Character, .NChar, .Clob:
                return field.length >= 40 ? 120 : 180
            default:
                let w = width < 30 ? 40 : width
                return field.primary ? w + 20 : w
            }
        }
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow row: Int) -> CGFloat {
        return 0 == row ? 60 : 50
    }
    
    func frozenRows(in spreadsheetView: SpreadsheetView) -> Int {
        return 1
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        if case 0 = indexPath.row {
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: String(describing: HeaderCell.self), for: indexPath) as! HeaderCell
            let field = fields[indexPath.column]
            var fieldName = field.name
            if field.primary {
                fieldName = fieldName + "🔑"
            }
            cell.label.text = fieldName + "\n" + fields[indexPath.column].type.rawValue
            
            let attributedText = NSMutableAttributedString(string: cell.label.text!)
            
            let range = (cell.label.text! as NSString).range(of: fields[indexPath.column].type.rawValue)
            if range.location != NSNotFound {
                attributedText.setAttributes([
                    NSFontAttributeName: UIFont.systemFont(ofSize: 11),
                    NSForegroundColorAttributeName: UIColor.gray],
                                             range: range)
            }
            cell.label.attributedText = attributedText
            
            if case indexPath.column = sortedColumn.column {
                cell.sortArrow.text = sortedColumn.sorting.symbol
            } else {
                cell.sortArrow.text = ""
            }
            cell.setNeedsLayout()
            
            return cell
        } else {
            let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: String(describing: TextCell.self), for: indexPath) as! TextCell
            let field = fields[indexPath.column].name
            let item = records[indexPath.row - 1]
            var text = item[field].debugDescription
            
            switch item[field] {
            case let value as String   : text = value
            case let value as Int      : text = String(value)
            case let value as Double   : text = String(value)
            case let value as NSNumber : text = String(describing: value)
            default: text = "\(item[text]!)"
            }
            
            cell.label.text = text
            
            if indexPath.row % 2 == 0 {
                cell.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
            } else {
                cell.backgroundColor = UIColor.white
            }
            
            return cell
        }
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, didSelectItemAt indexPath: IndexPath) {
        let field = fields[indexPath.column].name
        let item = records[indexPath.row == 0 ? 0 : indexPath.row - 1]
        var text = item[field].debugDescription

        switch item[field] {
        case let value as String   : text = value
        case let value as Int      : text = String(value)
        case let value as Double   : text = String(value)
        case let value as NSNumber : text = String(describing: value)
        default: text = "\(item[text]!)"
        }
        
        if case 0 = indexPath.row {
            if sortedColumn.column == indexPath.column {
                sortedColumn.sorting = sortedColumn.sorting == .ascending ? .descending : .ascending
            } else {
                sortedColumn = (indexPath.column, .ascending)
            }
            records.sort(by: { (v1, v2) -> Bool in
                let ascending = v1[field].debugDescription < v2[field].debugDescription
                return sortedColumn.sorting == .ascending ? ascending : !ascending
            })
            
            spreadsheetView.reloadData()
            return
        }
    }
}


// MARK: - UIScrollViewDelegate
//extension BrowseViewController: UIScrollViewDelegate {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard isPullable else { return }
//        guard scrollView.contentSize.height > scrollView.bounds.height && scrollView.bounds.height > 0 else { return }
//
//        let contentOffsetBottom = scrollView.contentOffset.y + scrollView.bounds.height
//        if contentOffsetBottom >= scrollView.contentSize.height - (scrollView.bounds.height / 2) {
//            isPullable = false
//
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
//                self.nextPage()
//            })
//
//        }
//    }
//}


// MARK: - UIViewControllerPreviewingDelegate
extension BrowseViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = spreadsheetView.indexPathForItem(at: location),
            indexPath.row != 0 else { return nil }
        
        let field = fields[indexPath.column].name
        let item = records[indexPath.row == 0 ? 0 : indexPath.row - 1]
        var text = item[field].debugDescription
        
        switch item[field] {
        case let value as String   : text = value
        case let value as Int      : text = String(value)
        case let value as Double   : text = String(value)
        case let value as NSNumber : text = String(describing: value)
        default: text = "\(item[text]!)"
        }
        
        let viewController = DetailViewController()
        viewController.value = text
        
        viewController.preferredContentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 0.7)
        
        previewingContext.sourceRect = view.frame
        
        return viewController
    }
}


// MARK: - String Width
extension String {
    /// 字符串大小
    func toSize(size: CGSize, fontSize: CGFloat, maximumNumberOfLines: Int = 0) -> CGSize {
        let font = UIFont.systemFont(ofSize: fontSize)
        var size = self.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes:[NSFontAttributeName : font], context: nil).size
        if maximumNumberOfLines > 0 {
            size.height = min(size.height, CGFloat(maximumNumberOfLines) * font.lineHeight)
        }
        return size
    }
    
    /// 字符串宽度
    func toWidth(fontSize: CGFloat, maximumNumberOfLines: Int = 0) -> CGFloat {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return toSize(size: size, fontSize: fontSize, maximumNumberOfLines: maximumNumberOfLines).width
    }
}
