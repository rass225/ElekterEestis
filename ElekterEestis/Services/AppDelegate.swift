import UIKit
import BackgroundTasks

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: SharedConstants.bgRefreshTaskId,
            using: nil
        ) { task in
            let task = task as! BGAppRefreshTask
            Task {
                await BackgroundRefreshRunner.run(task: task)
            }
        }

        return true
    }
}
