// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Redux

protocol SummaryCoordinatorDelegate: AnyObject {
    func didFinishSummary(from coordinator: SummaryCoordinator)
}

class SummaryCoordinator: BaseCoordinator, SummaryDelegate {
    func didFinishSummary(from coordinator: SummaryCoordinator) {
        parentCoordinator?.didFinishSummary(from: self)
    }
    
    var summaryViewController: SummaryScreen
    private let tabManager: TabManager
    private let themeManager: ThemeManager
    weak var parentCoordinator: SummaryCoordinatorDelegate?
    private var windowUUID: WindowUUID { return tabManager.windowUUID }

    init(router: Router,
         tabManager: TabManager,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.summaryViewController = SummaryViewController(with: tabManager)
        super.init(router: router)

        router.setRootViewController(summaryViewController)
        summaryViewController.summaryDelegate = self
    }
    
    func start() {
        summaryViewController.showSummary()
    }

    // MARK: - ParentCoordinatorDelegate

    func didFinish() {
        parentCoordinator?.didFinishSummary(from: self)
    }
}
