from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, DecimalField, BooleanField, SelectField, MultipleFileField, SubmitField
from wtforms.validators import DataRequired, Length, NumberRange
from flask_wtf.file import FileAllowed, FileRequired

class ProductForm(FlaskForm):
    title       = StringField('Título', validators=[DataRequired(), Length(max=150)])
    description = TextAreaField('Descrição', validators=[DataRequired(), Length(max=2000)])
    price       = DecimalField('Preço (€)', validators=[DataRequired(), NumberRange(min=0)])
    is_negotiable = BooleanField('Preço negociável?')
    category    = SelectField('Categoria', coerce=int, validators=[DataRequired()])
    subcategory = SelectField('Subcategoria', coerce=int, validators=[DataRequired()])
    photos = MultipleFileField(
        'Fotos',
        validators=[
            FileAllowed(['jpg','jpeg','png','gif'], 'Somente imagens!'),
            FileRequired('Selecione pelo menos uma foto.')
        ],
        render_kw={
            # aceita apenas estes tipos de ficheiro no diálogo
            'accept': '.jpg,.jpeg,.png,.gif'
        }
    )
    submit      = SubmitField('Salvar')
