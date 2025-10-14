import UIKit
import XExtensionItem

class ContentViewController: UIViewController {
    
    // MARK: - Properties
    private var contentItems: [ContentItem] = []
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(ContentItemCell.self, forCellReuseIdentifier: ContentItemCell.reuseIdentifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        return table
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadSampleData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Share Content"
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    // MARK: - Data Loading
    private func loadSampleData() {
        contentItems = [
            ContentItem(
                type: .image,
                title: "Product Image",
                subtitle: "High-resolution product photo",
                content: UIImage(named: "thumbnail") ?? UIImage()
            ),
            ContentItem(
                type: .pdf,
                title: "Technical Documentation",
                subtitle: "User manual and specifications (PDF)",
                content: URL(string: "https://example.com/manual.pdf")!
            ),
            ContentItem(
                type: .excel,
                title: "Sales Report Q4 2024",
                subtitle: "Quarterly financial data and analytics",
                content: URL(string: "https://example.com/report.xlsx")!
            ),
            ContentItem(
                type: .word,
                title: "Project Proposal",
                subtitle: "Detailed project scope and timeline",
                content: URL(string: "https://example.com/proposal.docx")!
            ),
            ContentItem(
                type: .url,
                title: "Apple iPad Air 2",
                subtitle: "http://apple.com/ipad-air-2/",
                content: URL(string: "http://apple.com/ipad-air-2/")!
            )
        ]
        
        tableView.reloadData()
    }
    
    // MARK: - Share Action
    private func shareContent(_ item: ContentItem) {
        var itemSource: XExtensionItemSource?
        
        switch item.type {
        case .image:
            if let image = item.content as? UIImage {
                itemSource = XExtensionItemSource(image: image)
            }
        case .url:
            if let url = item.content as? URL {
                itemSource = XExtensionItemSource(url: url)
            }
        case .pdf, .excel, .word:
            // For documents, we use URL
            if let url = item.content as? URL {
                itemSource = XExtensionItemSource(url: url)
            }
        }
        
        guard let source = itemSource else {
            showAlert(title: "Error", message: "Unable to share this content")
            return
        }
        
        // Add metadata
        source.title = item.title
        source.attributedContentText = NSAttributedString(string: item.subtitle)
        source.tags = generateTags(for: item.type)
        
        // Add referrer information
        source.referrer = XExtensionItemReferrer(
            appNameFrom: Bundle.main,
            appStoreID: "12345",
            googlePlayID: "12345",
            webURL: URL(string: "http://myservice.com/content"),
            iOSAppURL: URL(string: "myservice://content"),
            androidAppURL: URL(string: "myservice://content")
        )
        
        // Present activity view controller
        let activityVC = UIActivityViewController(
            activityItems: [source],
            applicationActivities: nil
        )
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    private func generateTags(for type: ContentItemType) -> [String] {
        switch type {
        case .image:
            return ["image", "photo", "visual"]
        case .pdf:
            return ["pdf", "document", "file"]
        case .excel:
            return ["excel", "spreadsheet", "data"]
        case .word:
            return ["word", "document", "text"]
        case .url:
            return ["link", "url", "web"]
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ContentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ContentItemCell.reuseIdentifier,
            for: indexPath
        ) as? ContentItemCell else {
            return UITableViewCell()
        }
        
        let item = contentItems[indexPath.row]
        cell.configure(with: item)
        cell.accessoryType = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Available Content"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Tap any item to share via available extensions and activities"
    }
}

// MARK: - UITableViewDelegate
extension ContentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = contentItems[indexPath.row]
        shareContent(item)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
