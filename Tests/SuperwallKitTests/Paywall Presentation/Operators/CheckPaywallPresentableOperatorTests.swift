//
//  File.swift
//  
//
//  Created by Yusuf Tör on 06/12/2022.
//

import XCTest
@testable import SuperwallKit
import Combine

final class CheckPaywallPresentableOperatorTests: XCTestCase {
  var cancellables: [AnyCancellable] = []
  let superwall = Superwall.shared

  @MainActor
  func test_checkPaywallIsPresentable_userIsSubscribed() async {
    let experiment = Experiment(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: ""))

    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")

    statePublisher.sink { state in
      switch state {
      case .skipped(let reason):
        switch reason {
        case .userIsSubscribed:
          stateExpectation.fulfill()
        default:
          break
        }
      default:
        break
      }
    }
    .store(in: &cancellables)
    let dependencyContainer = DependencyContainer(apiKey: "")
    let request = PresentationRequest.stub()
      .setting(\.injections.isUserSubscribed, to: true)

    let input = PaywallVcPipelineOutput(
      request: request,
      triggerResult: .paywall(experiment),
      debugInfo: [:],
      paywallViewController: dependencyContainer.makePaywallViewController(for: .stub()),
      confirmableAssignment: nil
    )

    let expectation = expectation(description: "Called publisher")
    CurrentValueSubject(input)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
      .checkPaywallIsPresentable(statePublisher)
      .eraseToAnyPublisher()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure:
            expectation.fulfill()
          default:
            break
          }
        },
        receiveValue: { output in
          XCTFail()
        }
      )
      .store(in: &cancellables)

    try? await Task.sleep(nanoseconds: 1_000_000)

    wait(for: [expectation, stateExpectation], timeout: 0.1)
  }

  @MainActor
  func test_checkPaywallIsPresentable_noPresenter() async {
    let experiment = Experiment(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: ""))

    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")
    stateExpectation.expectedFulfillmentCount = 2

    statePublisher.sink { completion in
      switch completion {
      case .finished:
        stateExpectation.fulfill()
      }
    } receiveValue: { state in
      switch state {
      case .skipped(let reason):
        switch reason {
        case .error:
          stateExpectation.fulfill()
        default:
          break
        }
      default:
        break
      }
    }
    .store(in: &cancellables)

    // TODO: Fix this. Before I set superwall to a strong ref?
    let dependencyContainer = DependencyContainer(apiKey: "abc")
    let request = dependencyContainer.makePresentationRequest(
      .explicitTrigger(.stub()),
      isDebuggerLaunched: false,
      isUserSubscribed: false,
      isPaywallPresented: false
    )
      .setting(\.presentingViewController, to: nil)
      .setting(\.injections.superwall.presentationItems.window, to: UIWindow())

    let input = PaywallVcPipelineOutput(
      request: request,
      triggerResult: .paywall(experiment),
      debugInfo: [:],
      paywallViewController: dependencyContainer.makePaywallViewController(for: .stub()),
      confirmableAssignment: nil
    )

    let expectation = expectation(description: "Called publisher")
    CurrentValueSubject(input)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
      .checkPaywallIsPresentable(statePublisher)
      .eraseToAnyPublisher()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure:
            expectation.fulfill()
          default:
            break
          }
        },
        receiveValue: { output in
          XCTFail()
        }
      )
      .store(in: &cancellables)

    try? await Task.sleep(nanoseconds: 1_000_000)

    wait(for: [expectation, stateExpectation], timeout: 1)
  }

  @MainActor
  func test_checkPaywallIsPresentable_success() async {
    let experiment = Experiment(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: ""))

    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")
    stateExpectation.isInverted = true

    statePublisher.sink { completion in
      stateExpectation.fulfill()
    } receiveValue: { state in
      stateExpectation.fulfill()
    }
    .store(in: &cancellables)

    let request = PresentationRequest.stub()
      .setting(\.presentingViewController, to: UIViewController())
      .setting(\.injections.isUserSubscribed, to: false)

    let dependencyContainer = DependencyContainer(apiKey: "")
    let input = PaywallVcPipelineOutput(
      request: request,
      triggerResult: .paywall(experiment),
      debugInfo: [:],
      paywallViewController: dependencyContainer.makePaywallViewController(for: .stub()),
      confirmableAssignment: nil
    )

    let expectation = expectation(description: "Called publisher")
    CurrentValueSubject(input)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
      .checkPaywallIsPresentable(statePublisher)
      .eraseToAnyPublisher()
      .sink(
        receiveCompletion: { completion in
          XCTFail()
        },
        receiveValue: { output in
          expectation.fulfill()
        }
      )
      .store(in: &cancellables)

    try? await Task.sleep(nanoseconds: 1_000_000)

    wait(for: [expectation, stateExpectation], timeout: 0.1)
  }
}
