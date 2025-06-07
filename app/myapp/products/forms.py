# forms.py
from flask_wtf import FlaskForm
from wtforms import (
    StringField, TextAreaField, DecimalField, BooleanField,
    SelectField, MultipleFileField, SubmitField
)
from wtforms.validators import DataRequired, Length, NumberRange
from flask_wtf.file import FileAllowed

class ProductForm(FlaskForm):
    title         = StringField('Título', validators=[DataRequired(), Length(max=150)])
    description   = TextAreaField('Descrição', validators=[DataRequired(), Length(max=2000)])
    price         = DecimalField('Preço (€)', validators=[DataRequired(), NumberRange(min=0)])
    is_negotiable = BooleanField('Preço negociável?')
    
    # Novo campo para estado (conservação)
    estado = SelectField(
        'Estado de Conservação',
        choices=[
            ('novo', 'Novo'),
            ('seminovo', 'Semi‐novo'),
            ('usado', 'Usado'),
            ('recondicionado', 'Recondicionado')
        ],
        validators=[DataRequired()]
    )
    
    category    = SelectField('Categoria', coerce=int, validators=[DataRequired()])
    subcategory = SelectField('Subcategoria', coerce=int, validators=[DataRequired()])

    photos = MultipleFileField(
        'Fotos',
        validators=[
            FileAllowed(['jpg','jpeg','png','gif'], 'Somente imagens!')
        ],
        render_kw={
            'accept': '.jpg,.jpeg,.png,.gif'
        }
    )
    submit      = SubmitField('Salvar')