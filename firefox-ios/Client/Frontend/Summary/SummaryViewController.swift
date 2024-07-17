// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import ComponentLibrary

// MARK: - Summary Delegate Protocol

/// Supports decision making from VC to parent coordinator
@objc
protocol SummaryDelegate: AnyObject {
    func didFinish()
}

protocol SummaryScreen: UIViewController {
    var summaryDelegate: SummaryDelegate? { get set }
    func showSummary()
}

// MARK: - Summary View Controller

/// Summary Screen (triggered by tapping 'Summarize Page' in the Tab Tray Controller)
class SummaryViewController: UIViewController, SummaryScreen {
    // MARK: - Properties
    private var applicationHelper: ApplicationHelper
    var tabManager: TabManager!
    weak var summaryDelegate: SummaryDelegate?
    let windowUUID: WindowUUID
    
    private lazy var scrollView: FadeScrollView = .build { scrollView in
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    let textView = UILabel()
    private lazy var contentView: UIView = .build { _ in }
    private lazy var scrollContentView: UIView = .build { _ in }
    
    private lazy var loadingIndicator: UIActivityIndicatorView = .build { [self] loadingIndicator in
        loadingIndicator.style = .medium
        loadingIndicator.hidesWhenStopped = true
    }
    
    // MARK: - Initializers
    init(with tabManager: TabManager,
         delegate: SummaryDelegate? = nil,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()) {
        self.applicationHelper = applicationHelper
        self.windowUUID = tabManager.windowUUID
        self.tabManager = tabManager
        self.summaryDelegate = delegate
        super.init(nibName: nil, bundle: nil)
        setupNavigationBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        configureAccessibilityIdentifiers()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Private
    
    private func setupView() {
        self.view.backgroundColor = .white
        scrollView.addSubview(scrollContentView)
        contentView.addSubviews(scrollView)
        view.addSubviews(contentView)
        view.addSubview(loadingIndicator)
        view.accessibilityElements = [contentView]
        
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(
            greaterThanOrEqualTo: scrollContentView.heightAnchor)
        
        textView.numberOfLines = 0
        textView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            scrollContentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollViewHeightConstraint,
            textView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            textView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            textView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        scrollViewHeightConstraint.priority = .defaultLow
    }
    
    // MARK: - Summary
    func showSummary() {
        loadingIndicator.startAnimating()
        
        let headers = [
            "x-rapidapi-key": "<RAPID API KEY>",
            "x-rapidapi-host": "tldrthis.p.rapidapi.com",
            "Content-Type": "application/json"
        ]
        
        let parameters = [
            "url": tabManager.selectedTab?.url?.absoluteString as Any,
            "min_length": 100,
            "max_length": 300,
            "is_detailed": false
        ] as [String : Any]
        
        var request = URLRequest(url: URL(string: "https://tldrthis.p.rapidapi.com/v1/model/abstractive/summarize-url/")! as URL,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            
            if let summary = try? JSONDecoder().decode(Summary.self, from: data).summary.first {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.textView.text = summary
                }
            }
        }
        
        dataTask.resume()
    }
    
    // MARK: - Actions
    
    @objc
    private func done() {
        summaryDelegate?.didFinish()
    }
    
    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        navigationItem.title = String.SummaryTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: .AppSettingsDone,
            style: .done,
            target: self,
            action: #selector(done))
    }
    
    // MARK: - Accessibility Identifiers
    func configureAccessibilityIdentifiers() {
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Settings.navigationBarItem
        view.accessibilityIdentifier = AccessibilityIdentifiers.Summary.viewController
    }
}

struct Summary: Codable {
    let summary: [String]
}

enum SummaryError: Error, CustomStringConvertible {
    case summaryNotCreated
    
    var description: String {
        return "The sumary could not be created."
    }
}
