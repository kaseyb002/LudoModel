import Foundation

public enum LudoError: Error, Equatable, Sendable {
    case notEnoughPlayers
    case tooManyPlayers
    case duplicateColors
    case notWaitingForRoll
    case notWaitingForTokenChoice
    case tokenNotFound
    case tokenDoesNotBelongToPlayer
    case illegalMove
    case gameAlreadyComplete
    case invalidDieValue
}
