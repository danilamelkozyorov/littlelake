//
//  BoardGameController.swift
//  Cards
//
//  Created by Мелкозеров Данила on 23.03.2022.
//

import UIKit

class BoardGameController: UIViewController {
    
    // размеры карточек
    private var cardSize: CGSize { CGSize(width: 80, height: 120) }
    private var flippedCards = [UIView]()
    
    private var cardMaxXCoordinate: Int {
        Int(boardGameView.frame.width - cardSize.width)
    }
    private var cardMaxYCoordinate: Int {
        Int(boardGameView.frame.height - cardSize.height)
    }
    
    // количество пар уникальных карточек
    var cardsPairsCounts = 8
    var cardViews = [UIView]()

    //кнопка запуска/перезапуска игры
    lazy var startButtonView = getStartButtonView()
    // сущность "Игра"
    lazy var game: Game = getNewGame()
    lazy var boardGameView = getBoardGameView()

    
    override func loadView() {
        super.loadView()
        
        view.addSubview(startButtonView)
        view.addSubview(boardGameView)
    }
    
    private func getNewGame() -> Game {
        let game = Game()
        game.cardsCount = self.cardsPairsCounts
        game.generateCards()
        return game
    }
    
    private func placeCardsOnBoard(_ cards: [UIView]) {
        // удаляем все имеющиеся на игровом поле карточки
        for card in cardViews {
            card.removeFromSuperview()
        }
        cardViews = cards
        // перебираем карточки
        for card in cardViews {
            // для каждой карточки генерируем случайные координаты
            let randomXCoordinate = Int.random(in: 0...cardMaxXCoordinate)
            let randomYCoordinate = Int.random(in: 0...cardMaxYCoordinate)
            card.frame.origin = CGPoint(x: randomXCoordinate, y: randomYCoordinate)
            // размещаем карточку на игровом поле
            boardGameView.addSubview(card)
        }
    }

    private func getBoardGameView() -> UIView {
    // отступ игрового поля от ближайших элементов
        let margin: CGFloat = 10
        let boardView = UIView()
        // указываем координаты
        // x
        boardView.frame.origin.x = margin
        // y
        let window = UIApplication.shared.windows[0]
        let topPadding = window.safeAreaInsets.top
        boardView.frame.origin.y = topPadding + startButtonView.frame.height + margin
        // рассчитываем ширину
        boardView.frame.size.width = UIScreen.main.bounds.width - margin*2
        // рассчитываем высоту
        // c учетом нижнего отступа
        let bottomPadding = window.safeAreaInsets.bottom
        boardView.frame.size.height = UIScreen.main.bounds.height - boardView.frame.origin.y - margin - bottomPadding
        // изменяем стиль игрового поля
        boardView.layer.cornerRadius = 5
        boardView.backgroundColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.3)
        return boardView
    }
    
    private func getStartButtonView() -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        button.center.x = view.center.x
        button.setTitle("Начать игру", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.darkGray, for: .highlighted)
        button.backgroundColor = .systemGray4
        button.layer.cornerRadius = 10
        
        let window = UIApplication.shared.windows[0]
        let padding = window.safeAreaInsets.top
        button.frame.origin.y = padding
        // подключаем обработчик нажатия на кнопку
        button.addTarget(nil, action: #selector(startGame(_:)), for: .touchUpInside)
        
        return button
    }
    
    // генерация массива карточек на основе данных Модели
    private func getCardsBy(modelData: [Card]) -> [UIView] {
        // хранилище для представлений карточек
        var cardViews = [UIView]()
        // фабрика карточек
        let cardViewFactory = CardViewFactory()
        // перебираем массив карточек в Модели
        for (index, modelCard) in modelData.enumerated() {
            // добавляем первый экземпляр карты
            let cardOne = cardViewFactory.get(modelCard.type, withSize: cardSize, andColor: modelCard.color)
            cardOne.tag = index
            cardViews.append(cardOne)
            // добавляем второй экземпляр карты
            let cardTwo = cardViewFactory.get(modelCard.type, withSize: cardSize, andColor: modelCard.color)
            cardTwo.tag = index
            cardViews.append(cardTwo)
        }
        // добавляем всем картам обработчик переворота
        for card in cardViews {
            (card as! FlippableView).flipCompletionHandler = {
                flippedCard in flippedCard.superview?.bringSubviewToFront(flippedCard)
            }
        }
        // добавляем всем картам обработчик переворота
        for card in cardViews {
            (card as! FlippableView).flipCompletionHandler = { [self] flippedCard in flippedCard.superview?.bringSubviewToFront(flippedCard)
                // добавляем или удаляем карточку
                if flippedCard.isFlipped {
                    self.flippedCards.append(flippedCard)
                } else {
                    if let cardIndex = self.flippedCards.firstIndex(of: flippedCard) {
                        self.flippedCards.remove(at: cardIndex)
                    }
                }
                // если перевернуто 2 карточки
                if self.flippedCards.count == 2 {
                    // получаем карточки из данных модели
                    let firstCard = game.cards[self.flippedCards.first!.tag]
                    let secondCard = game.cards[self.flippedCards.last!.tag]
                    // если карточки одинаковые
                    if game.checkCards(firstCard, secondCard) {
                        // сперва анимировано скрываем их
                        UIView.animate(withDuration: 0.3, animations: {
                            self.flippedCards.first!.layer.opacity = 0
                            self.flippedCards.last!.layer.opacity = 0
                            // после чего удаляем из иерархии
                        }, completion: {_ in
                            self.flippedCards.first!.removeFromSuperview()
                            self.flippedCards.last!.removeFromSuperview()
                            self.flippedCards = []
                        })
                        // в ином случае
                    } else {
                        // переворачиваем карточки рубашкой вверх
                        for card in self.flippedCards {
                            (card as! FlippableView).flip() }
                    }
                }
            }
        }
        return cardViews
    }

    @objc func startGame(_ sender: UIButton) {
        print("button was pressed")
        game = getNewGame()
        let cards = getCardsBy(modelData: game.cards)
        placeCardsOnBoard(cards)
    }
}
