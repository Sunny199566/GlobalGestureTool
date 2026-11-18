import SwiftUI
import Foundation

struct AppItem: Identifiable {
    let id = UUID()
    let bundleID: String
    let appName: String
}

struct ScriptFile: Identifiable {
    let id = UUID()
    let name: String
    let fullPath: String
}

class AppWorkspace: NSObject {
    static let shared = AppWorkspace()
    private let ws = NSClassFromString("LSApplicationWorkspace")!
        .perform(Selector(("defaultWorkspace")))!
        .takeUnretainedValue()
    
    func killApp(bundleId: String) {
        ws.perform(Selector(("killApplicationWithBundleID:")), with: bundleId)
    }
    
    func openApp(bundleId: String) -> Bool {
        return ws.perform(Selector(("openApplicationWithBundleID:")), with: bundleId)
            .takeUnretainedValue() as! Bool
    }
    
    func isRunning(bundleId: String) -> Bool {
        guard let runningApps = ws.perform(Selector(("runningApplications")))
            .takeUnretainedValue() as? [AnyObject] else { return false }
        for app in runningApps {
            guard let bid = app.perform(Selector(("bundleIdentifier")))
                .takeUnretainedValue() as? String else { continue }
            if bid == bundleId { return true }
        }
        return false
    }
    
    func getAllApps() -> [AppItem] {
        guard let installed = ws.perform(Selector(("allInstalledApplications")))
            .takeUnretainedValue() as? [AnyObject] else { return [] }
        var list: [AppItem] = []
        for item in installed {
            guard let bid = item.perform(Selector(("bundleIdentifier"))).takeUnretainedValue() as? String,
                  let name = item.perform(Selector(("localizedName"))).takeUnretainedValue() as? String else { continue }
            list.append(AppItem(bundleID: bid, appName: name))
        }
        return list.sorted { $0.appName < $1.appName }
    }
}

class ScriptManager: ObservableObject {
    @Published var appList: [AppItem] = []
    @Published var selectedApp: AppItem?
    @Published var scripts: [ScriptFile] = []
    
    private let ud = UserDefaults.standard
    private let injectDir = "/var/jb/TrollFools/"
    private let tweakDylibPath = "/var/jb/Library/RecordTweak/RecordTweak.dylib"
    private let scriptDir = "/var/jb/GlobalGestures"
    
    func loadAppList() {
        appList = AppWorkspace.shared.getAllApps()
    }
    
    func loadScripts() {
        scripts.removeAll()
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: scriptDir) else { return }
        for f in files {
            if f.hasSuffix(".dat") {
                let full = (scriptDir as NSString).appendingPathComponent(f)
                scripts.append(ScriptFile(name: f, fullPath: full))
            }
        }
    }

    // ==========【新增：选中脚本，传给PlayDaemon回放进程】==========
    func selectScriptForPlay(item: ScriptFile) {
        ud.set(item.fullPath, forKey: "GesturePlayer_SelectedScriptPath")
        ud.synchronize()
    }
    
    func writeInjectPlist(bundleId: String) {
        let plistPath = injectDir + bundleId + ".plist"
        let plist: [String: Any] = [
            "dylibs": [tweakDylibPath],
            "bundleIdentifier": bundleId
        ]
        (plist as NSDictionary).write(toFile: plistPath, atomically: true)
    }
    
    func removeInjectPlist(bundleId: String) {
        let plistPath = injectDir + bundleId + ".plist"
        try? FileManager.default.removeItem(atPath: plistPath)
    }
    
    func startRecord(target: AppItem) {
        let bid = target.bundleID
        writeInjectPlist(bundleId: bid)
        
        if AppWorkspace.shared.isRunning(bundleId: bid) {
            AppWorkspace.shared.killApp(bundleId: bid)
        }
        AppWorkspace.shared.openApp(bundleId: bid)
        
        ud.set(false, forKey: "GestureRecord_Finish")
        ud.removeObject(forKey: "GestureRecord_Finish_Name")
        ud.synchronize()
        
        DispatchQueue.global(qos: .background).async {
            while true {
                Thread.sleep(forTimeInterval: 0.8)
                let done = self.ud.bool(forKey: "GestureRecord_Finish")
                if done {
                    DispatchQueue.main.async {
                        self.removeInjectPlist(bundleId: bid)
                        AppWorkspace.shared.killApp(bundleId: bid)
                        self.loadScripts()
                    }
                    break
                }
            }
        }
    }
    
    func deleteScript(item: ScriptFile) {
        try? FileManager.default.removeItem(atPath: item.fullPath)
        loadScripts()
    }
}

@main
struct GestureManagerApp: App {
    @StateObject private var vm = ScriptManager()
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    Section("选择录制目标App") {
                        Picker("应用", selection: $vm.selectedApp) {
                            ForEach(vm.appList) { app in
                                Text("\(app.appName) (\(app.bundleID))").tag(Optional(app))
                            }
                        }
                        if let selected = vm.selectedApp {
                            Button("✅ 一键开始录制：\(selected.appName)") {
                                vm.startRecord(target: selected)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                    Section("已保存手势脚本 (.dat)") {
                        ForEach(vm.scripts) { s in
                            HStack {
                                Text(s.name)
                                Spacer()
                                // ==========【新增：选择回放按钮】==========
                                Button("选择回放") {
                                    vm.selectScriptForPlay(item: s)
                                }
                                Button("删除", role: .destructive) {
                                    vm.deleteScript(item: s)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("全局手势录制管理器")
                .onAppear {
                    vm.loadAppList()
                    vm.loadScripts()
                }
                .refreshable {
                    vm.loadAppList()
                    vm.loadScripts()
                }
            }
        }
    }
}