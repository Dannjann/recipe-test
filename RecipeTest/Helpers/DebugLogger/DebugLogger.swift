//
//  DebugLogger.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//
import Foundation
import os.log
import Synchronization

nonisolated enum LogLevel: String {
  case debug
  case info
  case error
  case fault
}

/// A singleton logger class for debug printing, allowing enabling or disabling logs for specific contexts.
final nonisolated class DebugLogger: Sendable {
  static let shared: DebugLogger = .init(enabledContexts: [], showLocation: false)

  /// Logging is reachable from every isolation, so the mutable configuration sits behind
  /// a lock rather than an actor — callers stay synchronous.
  private struct Configuration {
    var enabledContexts: Set<Context>
    var isLoggingEnabled: Bool
    var showLocation: Bool
  }

  private let configuration: Mutex<Configuration>

  /// Global flag to enable or disable logging
  var isLoggingEnabled: Bool {
    get { configuration.withLock { $0.isLoggingEnabled } }
    set { configuration.withLock { $0.isLoggingEnabled = newValue } }
  }

  /// Global flag to show location information
  var showLocation: Bool {
    get { configuration.withLock { $0.showLocation } }
    set { configuration.withLock { $0.showLocation = newValue } }
  }

  /// Initializer to enable specific contexts and set location flag
  init(
    enabledContexts: [Context],
    showLocation: Bool = false
  ) {
    configuration = Mutex(
      Configuration(
        enabledContexts: Set(enabledContexts),
        isLoggingEnabled: true,
        showLocation: showLocation
      )
    )
  }

  /// Enable logging for a specific context
  /// - Parameter context: The context to enable logging for
  func enable(
    _ context: Context
  ) {
    configuration.withLock { _ = $0.enabledContexts.insert(context) }
  }

  /// Disable logging for a specific context
  /// - Parameter context: The context to disable logging for
  func disable(
    _ context: Context
  ) {
    configuration.withLock { _ = $0.enabledContexts.remove(context) }
  }

  /// Check if logging is enabled for a specific context
  /// - Parameter context: The context to check
  /// - Returns: Boolean indicating if logging is enabled for the given context
  func isEnabled(
    _ context: Context
  ) -> Bool {
    configuration.withLock { $0.enabledContexts.contains(context) }
  }

  /// Log a message for a specific context using OSLog
  /// - Parameters:
  ///   - context: The context for the log message
  ///   - message: The log message
  ///   - newLine: Boolean indicating if a newline should be added after the message (default is true)
  ///   - level: The log level (default is debug)
  ///   - showLocationOverride: Optional flag to override the global `showLocation` flag
  ///   - file: The file name where the log is called
  ///   - line: The line number where the log is called
  ///   - function: The function name where the log is called
  func log(
    _ context: Context,
    _ message: String,
    newLine: Bool = true,
    level: LogLevel = .debug,
    showLocationOverride: Bool? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) {
    guard isLoggingEnabled, isEnabled(context) else { return }

    let locationFlag = showLocationOverride ?? showLocation
    let logMessage = newLine ? "\(message)\n" : message
    let locationInfo = locationFlag ? "[\(sourceFileName(filePath: file)):\(line)] \(function) - " : ""
    let fullMessage = "\(locationInfo)\(logMessage)"

    let osLogType: OSLogType =
      switch level {
      case .debug:
        .debug
      case .info:
        .info
      case .error:
        .error
      case .fault:
        .fault
      }

    // The format string decides redaction and has to be a literal, so the two builds take
    // separate calls. Release marks the argument private: anything a caller chose to log
    // there stays out of the system log that Console.app and sysdiagnose can read.
    #if DEBUG
      os_log(
        "%{public}@",
        log: context.osLog,
        type: osLogType,
        fullMessage
      )
    #else
      os_log(
        "%{private}@",
        log: context.osLog,
        type: osLogType,
        fullMessage
      )
    #endif
  }

  /// Log a title for a specific context using OSLog, with special formatting for start or end titles
  /// - Parameters:
  ///   - context: The context for the log title
  ///   - title: The title message
  ///   - newLine: Boolean indicating if a newline should be added after the title (default is true)
  ///   - isStart: Boolean indicating if the title is a start title (default is true). If false, it is treated as an end title.
  ///   - level: The log level (default is debug)
  ///   - showLocationOverride: Optional flag to override the global `showLocation` flag
  ///   - file: The file name where the log is called
  ///   - line: The line number where the log is called
  ///   - function: The function name where the log is called
  func logTitle(
    _ context: Context,
    _ title: String,
    newLine: Bool = true,
    isStart: Bool = true,
    level: LogLevel = .debug,
    showLocationOverride: Bool? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) {
    guard isLoggingEnabled, isEnabled(context) else { return }

    let logTitleMessage = isStart ? "⭐️⭐️⭐️ \(title) ⭐️⭐️⭐️" : "🎉🎉🎉 \(title) 🎉🎉🎉"
    log(
      context,
      logTitleMessage,
      newLine: newLine,
      level: level,
      showLocationOverride: showLocationOverride,
      file: file,
      line: line,
      function: function
    )
  }

  /// Log a multi-line message for a specific context using OSLog
  /// - Parameters:
  ///   - context: The context for the log message
  ///   - message: The multi-line log message
  ///   - newLine: Boolean indicating if a newline should be added after each line (default is true)
  ///   - level: The log level (default is debug)
  ///   - showLocationOverride: Optional flag to override the global `showLocation` flag
  ///   - file: The file name where the log is called
  ///   - line: The line number where the log is called
  ///   - function: The function name where the log is called
  ///
  /// This method allows logging long messages by splitting them into multiple lines.
  func logMultiLine(
    _ context: Context,
    _ message: String,
    newLine: Bool = true,
    level: LogLevel = .debug,
    showLocationOverride: Bool? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) {
    guard isLoggingEnabled, isEnabled(context) else { return }

    let lines = message.split(separator: "\n")
    for logLine in lines {
      log(
        context,
        String(logLine),
        newLine: newLine,
        level: level,
        showLocationOverride: showLocationOverride,
        file: file,
        line: line,
        function: function
      )
    }
  }

  /// Internal struct for defining log contexts
  struct Context: Hashable, RawRepresentable {
    let rawValue: String
    let osLog: OSLog

    init(
      _ rawValue: String
    ) {
      self.rawValue = rawValue
      osLog = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "DebugLogger",
        category: rawValue
      )
    }

    init(
      rawValue: String
    ) {
      self.init(rawValue)
    }

    /// Identity is the category name, and nothing else.
    ///
    /// The synthesized conformance would have included `osLog` — an `NSObject`, and so
    /// compared by pointer — which made two separately constructed `Context("networking")`
    /// values unequal. `isEnabled(_:)` then reported `false` for a context that had been
    /// enabled, unless the caller passed one of the `static let` instances.
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(rawValue)
    }
  }
}

private nonisolated func sourceFileName(
  filePath: String
) -> String {
  let components = filePath.components(separatedBy: "/")
  return components.isEmpty ? "" : components.last!
}
