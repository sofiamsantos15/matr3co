from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField
from wtforms.validators import DataRequired, Length

class CheckoutForm(FlaskForm):
    card_number = StringField('Número do Cartão', validators=[DataRequired(), Length(min=13, max=19)])
    expiry_date = StringField('Data de Validade (MM/AA)', validators=[DataRequired(), Length(min=5, max=5)])
    cvv = StringField('CVV', validators=[DataRequired(), Length(min=3, max=4)])
    submit = SubmitField('Finalizar Compra')
