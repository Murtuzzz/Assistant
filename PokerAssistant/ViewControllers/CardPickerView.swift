import UIKit

protocol CardPickerViewDelegate: AnyObject {
    func cardPickerView(_ picker: CardPickerView, didSelectCard card: String)
}

class CardPickerView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {
    weak var delegate: CardPickerViewDelegate?
    private let picker = UIPickerView()
    private let cardLabel = UILabel()
    private let values = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
    private let suits = ["♠️", "♥️", "♦️", "♣️"]
    private var selectedValue = "A"
    private var selectedSuit = "♠️"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        picker.delegate = self
        picker.dataSource = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        addSubview(picker)
        
        cardLabel.text = "A♠️"
        cardLabel.textAlignment = .center
        cardLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        cardLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardLabel)
        
        NSLayoutConstraint.activate([
            cardLabel.topAnchor.constraint(equalTo: topAnchor),
            cardLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardLabel.heightAnchor.constraint(equalToConstant: 40),
            picker.topAnchor.constraint(equalTo: cardLabel.bottomAnchor, constant: 4),
            picker.leadingAnchor.constraint(equalTo: leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: trailingAnchor),
            picker.heightAnchor.constraint(equalToConstant: 120),
            picker.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? values.count : suits.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        component == 0 ? values[row] : suits[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedValue = values[picker.selectedRow(inComponent: 0)]
        selectedSuit = suits[picker.selectedRow(inComponent: 1)]
        let card = selectedValue + selectedSuit
        cardLabel.text = card
        delegate?.cardPickerView(self, didSelectCard: card)
    }
    
    func setCard(_ card: String) {
        guard card.count == 2 else { return }
        if let valueIdx = values.firstIndex(where: { $0 == String(card.first!) }),
           let suitIdx = suits.firstIndex(where: { $0 == String(card.last!) }) {
            picker.selectRow(valueIdx, inComponent: 0, animated: false)
            picker.selectRow(suitIdx, inComponent: 1, animated: false)
            cardLabel.text = card
        }
    }
    
    var selectedCard: String {
        return selectedValue + selectedSuit
    }
} 